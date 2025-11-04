import { createDbClient, createServiceClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
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
    const serviceClient = createServiceClient()
    
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()
    if (authError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { offer_id } = await req.json()
    if (!offer_id) {
      return new Response(
        JSON.stringify({ error: 'offer_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
    const { data: appUser } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.id)
      .single()

    if (!appUser || appUser.account_type !== 'professional' || appUser.active_role !== 'professional') {
      return new Response(
        JSON.stringify({ error: 'Only active professionals can accept offers' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get offer
    const { data: offer, error: offerError } = await supabase
      .from('offers')
      .select('*')
      .eq('id', offer_id)
      .single()

    if (offerError || !offer) {
      return new Response(
        JSON.stringify({ error: 'Offer not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (offer.status !== 'open') {
      return new Response(
        JSON.stringify({ error: 'Offer is not available', reasons: [`Offer status is ${offer.status}`] }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check compliance for all required trades
    const offerTrades = offer.trade || []
    const { data: compliance } = await serviceClient
      .from('pro_trade_compliance')
      .select('trade, compliant, reason')
      .eq('user_id', appUser.id)
      .in('trade', offerTrades)

    const reasons: string[] = []
    const nonCompliantTrades = (compliance || [])
      .filter(c => !c.compliant)
      .map(c => c.trade)

    if (nonCompliantTrades.length > 0) {
      reasons.push(`Not compliant for trades: ${nonCompliantTrades.join(', ')}`)
    }

    // Check if user is missing compliance records for any required trade
    const missingTrades = offerTrades.filter(t => !compliance?.some(c => c.trade === t))
    if (missingTrades.length > 0) {
      reasons.push(`Missing compliance verification for trades: ${missingTrades.join(', ')}`)
    }

    // Check verification status
    if (appUser.verification_status !== 'approved') {
      reasons.push(`Account verification status is ${appUser.verification_status}`)
    }

    // If any compliance issues, return 409
    if (reasons.length > 0) {
      return new Response(
        JSON.stringify({ error: 'Cannot accept offer: compliance issues', reasons }),
        { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create assignment
    const { error: assignError } = await serviceClient
      .from('offer_assignments')
      .insert({
        offer_id: offer.id,
        professional_user_id: appUser.id
      })

    if (assignError) {
      if (assignError.code === '23505') { // Unique violation
        return new Response(
          JSON.stringify({ error: 'Offer already assigned', reasons: ['This offer has already been assigned to you'] }),
          { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      return new Response(
        JSON.stringify({ error: assignError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update offer status
    await serviceClient
      .from('offers')
      .update({ status: 'assigned' })
      .eq('id', offer.id)

    return new Response(
      JSON.stringify({ success: true, offer_id: offer.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
