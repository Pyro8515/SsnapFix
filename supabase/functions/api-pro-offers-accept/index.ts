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

    const { offer_id, lat, lng, max_distance } = await req.json()
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
    const reasons: string[] = []

    // Check if offer requires any trades
    if (offerTrades.length === 0) {
      reasons.push('Offer does not specify required trades')
    } else {
      // Get compliance for all required trades
      const { data: compliance } = await serviceClient
        .from('pro_trade_compliance')
        .select('trade, compliant, reason')
        .eq('user_id', appUser.id)
        .in('trade', offerTrades)

      // Check each required trade
      for (const trade of offerTrades) {
        const tradeCompliance = compliance?.find(c => c.trade === trade)
        
        if (!tradeCompliance) {
          reasons.push(`Missing compliance verification for trade: ${trade}`)
        } else if (!tradeCompliance.compliant) {
          // Include detailed reason if available
          const reasonDetail = tradeCompliance.reason 
            ? ` (${tradeCompliance.reason})`
            : ''
          reasons.push(`Not compliant for trade "${trade}"${reasonDetail}`)
        }
      }
    }

    // Check verification status
    if (appUser.verification_status !== 'approved') {
      reasons.push(`Account verification status is "${appUser.verification_status}" (must be "approved")`)
    }

    // Check distance if coordinates provided
    if (lat && lng && offer.location_lat && offer.location_lng) {
      const userLat = parseFloat(lat)
      const userLng = parseFloat(lng)
      const offerLat = parseFloat(offer.location_lat)
      const offerLng = parseFloat(offer.location_lng)
      const maxDist = max_distance ? parseFloat(max_distance) : 50 // Default 50km

      if (!isNaN(userLat) && !isNaN(userLng) && !isNaN(offerLat) && !isNaN(offerLng) && !isNaN(maxDist)) {
        const distance = calculateDistance(userLat, userLng, offerLat, offerLng)
        if (distance > maxDist) {
          reasons.push(`Offer location is ${distance.toFixed(1)}km away (maximum allowed: ${maxDist}km)`)
        }
      }
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

// Haversine formula for distance calculation
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371 // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180
  const dLon = (lon2 - lon1) * Math.PI / 180
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  return R * c
}
