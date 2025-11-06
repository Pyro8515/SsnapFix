import { createDbClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    const supabase = createDbClient(req)

    // Get authenticated user
    const {
      data: { user: authUser },
      error: userError,
    } = await supabase.auth.getUser()

    if (userError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
    const { data: userData, error: userDataError } = await supabase
      .from('users')
      .select('id, active_role')
      .eq('id', authUser.id)
      .single()

    if (userDataError || !userData) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify user is customer
    if (userData.active_role !== 'customer') {
      return new Response(
        JSON.stringify({ error: 'Only customers can create jobs' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json()
    const { service_code, address, scheduled_start, scheduled_end, notes } = body

    // Validate required fields
    if (!service_code || !address || !address.lat || !address.lng) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: service_code, address with lat/lng' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify service exists and is active
    const { data: service, error: serviceError } = await supabase
      .from('services')
      .select('code, name, base_price_cents, diagnostic_fee_cents')
      .eq('code', service_code)
      .eq('is_active', true)
      .single()

    if (serviceError || !service) {
      return new Response(
        JSON.stringify({ error: 'Invalid or inactive service' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate price (base price + diagnostic fee)
    const price_cents = (service.base_price_cents || 0) + (service.diagnostic_fee_cents || 0)
    const platform_fee_cents = Math.round(price_cents * 0.10) // 10% platform fee
    const payout_cents = price_cents - platform_fee_cents

    // Create location point from lat/lng (PostGIS format: POINT(lng lat))
    const locationPoint = `POINT(${address.lng} ${address.lat})`

    // Create job using RPC or direct insert with PostGIS
    const { data: job, error: jobError } = await supabase.rpc('create_job_with_location', {
      p_customer_id: userData.id,
      p_service_code: service_code,
      p_address: address,
      p_location_lng: address.lng,
      p_location_lat: address.lat,
      p_scheduled_start: scheduled_start || null,
      p_scheduled_end: scheduled_end || null,
      p_price_cents: price_cents,
      p_platform_fee_cents: platform_fee_cents,
      p_payout_cents: payout_cents,
      p_notes: notes || null,
    })

    if (jobError) {
      // Fallback: try direct insert if RPC doesn't exist
      console.warn('RPC not found, using direct insert:', jobError)
      const { data: jobDirect, error: jobDirectError } = await supabase
        .from('jobs')
        .insert({
          customer_id: userData.id,
          service_code: service_code,
          status: 'requested',
          address: address,
          location: locationPoint,
          scheduled_start: scheduled_start || null,
          scheduled_end: scheduled_end || null,
          price_cents: price_cents,
          platform_fee_cents: platform_fee_cents,
          payout_cents: payout_cents,
          currency: 'USD',
          notes: notes || null,
        })
        .select()
        .single()

      if (jobDirectError) {
        console.error('Error creating job:', jobDirectError)
        return new Response(
          JSON.stringify({ error: 'Failed to create job', details: jobDirectError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Create job event
      await supabase
        .from('job_events')
        .insert({
          job_id: jobDirect.id,
          actor_user_id: userData.id,
          event: 'requested',
          location: locationPoint,
        })

      // Trigger matching engine (async - call matching function)
      // Note: This could be done via database trigger or direct function call
      // For now, we'll return the job and client can trigger matching separately
      // In production, you might want to call the matching function here:
      // fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/api-jobs-match`, {
      //   method: 'POST',
      //   headers: {
      //     'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
      //     'Content-Type': 'application/json',
      //   },
      //   body: JSON.stringify({ job_id: jobDirect.id }),
      // })

      return new Response(
        JSON.stringify({
          id: jobDirect.id,
          service_code: jobDirect.service_code,
          status: jobDirect.status,
          address: jobDirect.address,
          price_cents: jobDirect.price_cents,
          platform_fee_cents: jobDirect.platform_fee_cents,
          payout_cents: jobDirect.payout_cents,
          currency: jobDirect.currency,
          scheduled_start: jobDirect.scheduled_start,
          scheduled_end: jobDirect.scheduled_end,
          notes: jobDirect.notes,
          created_at: jobDirect.created_at,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create job event
    await supabase
      .from('job_events')
      .insert({
        job_id: job.id,
        actor_user_id: userData.id,
        event: 'requested',
        location: locationPoint,
      })

    // Trigger matching engine (call as edge function)
    // This will be handled by a database trigger or separate function
    // For now, we'll return the job and matching will happen async

    return new Response(
      JSON.stringify({
        id: job.id,
        service_code: job.service_code,
        status: job.status,
        address: job.address,
        price_cents: job.price_cents,
        platform_fee_cents: job.platform_fee_cents,
        payout_cents: job.payout_cents,
        currency: job.currency,
        scheduled_start: job.scheduled_start,
        scheduled_end: job.scheduled_end,
        notes: job.notes,
        created_at: job.created_at,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

