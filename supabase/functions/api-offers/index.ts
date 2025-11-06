import { createDbClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createDbClient(req)
    
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()
    if (authError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
    const { data: appUser } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.id)
      .single()

    if (!appUser) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get query params for filtering
    const url = new URL(req.url)
    const trade = url.searchParams.get('trade')
    const lat = url.searchParams.get('lat')
    const lng = url.searchParams.get('lng')
    const maxDistance = url.searchParams.get('max_distance') || '50' // km

    // Build query
    let query = supabase
      .from('offers')
      .select('*')
      .eq('status', 'open')

    // Filter by trade if provided
    if (trade) {
      query = query.contains('trade', [trade])
    }

    // Get offers
    const { data: offers, error } = await query

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Start with all offers
    let eligibleOffers = offers || []

    // If user is a professional, filter by trade compliance
    if (appUser.account_type === 'professional' && appUser.active_role === 'professional') {
      // Get user's compliant trades
      const { data: compliance } = await supabase
        .from('pro_trade_compliance')
        .select('trade')
        .eq('user_id', appUser.id)
        .eq('compliant', true)

      const compliantTrades = (compliance || []).map(c => c.trade)

      // Filter offers to only those where user is compliant for at least one required trade
      eligibleOffers = offers?.filter(offer => {
        const offerTrades = offer.trade || []
        return offerTrades.some(t => compliantTrades.includes(t))
      }) || []
    }

    // Apply distance filter if coordinates provided (for all users)
    if (lat && lng) {
      const userLat = parseFloat(lat)
      const userLng = parseFloat(lng)
      const maxDist = parseFloat(maxDistance)

      if (!isNaN(userLat) && !isNaN(userLng) && !isNaN(maxDist)) {
        eligibleOffers = eligibleOffers.filter(offer => {
          // Only check distance if offer has location
          if (!offer.location_lat || !offer.location_lng) {
            return true // Include offers without location
          }

          const offerLat = parseFloat(offer.location_lat)
          const offerLng = parseFloat(offer.location_lng)

          if (isNaN(offerLat) || isNaN(offerLng)) {
            return true // Include offers with invalid location
          }

          const distance = calculateDistance(userLat, userLng, offerLat, offerLng)
          return distance <= maxDist
        })
      }
    }

    return new Response(
      JSON.stringify(eligibleOffers),
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
