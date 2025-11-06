import { createDbClient, createServiceClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'
import { NotificationService } from '../_shared/notification_service.ts'

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
    const serviceClient = createServiceClient()
    const body = await req.json()
    const { job_id } = body

    if (!job_id) {
      return new Response(
        JSON.stringify({ error: 'Missing job_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get job details
    const { data: job, error: jobError } = await serviceClient
      .from('jobs')
      .select('*, services:service_code(code, name)')
      .eq('id', job_id)
      .single()

    if (jobError || !job) {
      return new Response(
        JSON.stringify({ error: 'Job not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Only match if job is in 'requested' status
    if (job.status !== 'requested') {
      return new Response(
        JSON.stringify({ error: 'Job already matched or completed' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract location from job
    const jobLocation = job.location
    if (!jobLocation) {
      return new Response(
        JSON.stringify({ error: 'Job location not found' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Find eligible pros
    // 1. Must have service enabled
    // 2. Must be online (is_online = true)
    // 3. Must be compliant for the service
    // 4. Must be within service area radius
    // 5. Order by: rating (desc), distance (asc)
    const { data: eligiblePros, error: prosError } = await serviceClient.rpc(
      'find_eligible_pros_for_job',
      {
        p_service_code: job.service_code,
        p_job_location: jobLocation,
        p_max_distance_km: 50, // Default 50km radius
      }
    )

    if (prosError) {
      // Fallback: manual query if RPC doesn't exist
      console.warn('RPC not found, using manual query:', prosError)
      
      // Get pros with service enabled
      const { data: prosWithService, error: serviceError } = await serviceClient
        .from('professional_profiles')
        .select(`
          user_id,
          services,
          base_location,
          current_location,
          is_online,
          rating_average,
          service_area_km,
          users!inner(id, phone, full_name)
        `)
        .contains('services', [job.service_code])
        .eq('is_online', true)

      if (serviceError) {
        console.error('Error finding pros:', serviceError)
        return new Response(
          JSON.stringify({ error: 'Failed to find eligible pros', details: serviceError.message }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Filter and rank pros manually
      // For now, we'll create offers for first 5 pros
      const eligiblePros = prosWithService?.slice(0, 5) || []
    }

    if (!eligiblePros || eligiblePros.length === 0) {
      return new Response(
        JSON.stringify({ 
          message: 'No eligible professionals found',
          matched_count: 0
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create job offers for eligible pros
    const offers = []
    const expiresAt = new Date(Date.now() + 30 * 60 * 1000) // 30 minutes

    for (const pro of eligiblePros) {
      // Calculate distance (if available)
      let distanceKm = null
      if (pro.distance_km) {
        distanceKm = pro.distance_km
      }

      // Create offer
      const { data: offer, error: offerError } = await serviceClient
        .from('job_offers')
        .insert({
          job_id: job_id,
          pro_user_id: pro.user_id,
          status: 'offered',
          expires_at: expiresAt.toISOString(),
          distance_km: distanceKm,
          payout_cents: job.payout_cents,
        })
        .select()
        .single()

      if (offerError) {
        console.error(`Error creating offer for pro ${pro.user_id}:`, offerError)
        continue
      }

      offers.push(offer)

      // Send SMS notification to pro
      if (pro.users?.phone) {
        try {
          const notificationService = new NotificationService(serviceClient)
          await notificationService.sendNotification({
            userId: pro.user_id,
            type: 'job_offer',
            title: 'New Job Offer',
            body: `${job.services?.name || job.service_code} - $${(job.price_cents / 100).toFixed(2)}. Expires in 30 minutes.`,
            data: {
              job_id: job_id,
              offer_id: offer.id,
              service_code: job.service_code,
              payout_cents: job.payout_cents,
            },
            channels: ['sms', 'in_app'],
          })
        } catch (smsError) {
          console.error(`Error sending notification to ${pro.users.phone}:`, smsError)
          // Continue even if notification fails
        }
      }
    }

    return new Response(
      JSON.stringify({
        message: 'Matching completed',
        matched_count: offers.length,
        offers: offers.map(o => ({
          id: o.id,
          pro_user_id: o.pro_user_id,
          status: o.status,
          expires_at: o.expires_at,
          payout_cents: o.payout_cents,
        })),
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in matching engine:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

