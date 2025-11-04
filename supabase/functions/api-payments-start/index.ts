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

    // Get app user
    const { data: appUser } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.id)
      .single()

    if (!appUser || appUser.account_type !== 'professional') {
      return new Response(
        JSON.stringify({ error: 'Only professionals can set up payments' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get professional profile
    const { data: profile } = await supabase
      .from('professional_profiles')
      .select('*')
      .eq('user_id', appUser.id)
      .single()

    if (!profile) {
      return new Response(
        JSON.stringify({ error: 'Professional profile not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeSecretKey) {
      return new Response(
        JSON.stringify({ error: 'Stripe not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const returnUrl = Deno.env.get('STRIPE_CONNECT_RETURN_URL') || 'https://your-app.com/connect-return'
    const refreshUrl = Deno.env.get('STRIPE_CONNECT_REFRESH_URL') || 'https://your-app.com/connect-refresh'

    // Create or get Stripe Connect account
    let accountId = profile.stripe_account_id

    if (!accountId) {
      // Create new Connect account
      const accountResponse = await fetch('https://api.stripe.com/v1/accounts', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${stripeSecretKey}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          type: 'express',
          country: 'US', // Default, could be parameterized
          email: authUser.email || ''
        })
      })

      const account = await accountResponse.json()
      
      if (!accountResponse.ok) {
        return new Response(
          JSON.stringify({ error: 'Failed to create Stripe account', details: account }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      accountId = account.id

      // Update profile
      await serviceClient
        .from('professional_profiles')
        .update({ stripe_account_id: accountId })
        .eq('user_id', appUser.id)
    }

    // Create account link
    const linkResponse = await fetch('https://api.stripe.com/v1/account_links', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        account: accountId,
        return_url: returnUrl,
        refresh_url: refreshUrl,
        type: 'account_onboarding'
      })
    })

    const link = await linkResponse.json()

    if (!linkResponse.ok) {
      return new Response(
        JSON.stringify({ error: 'Failed to create account link', details: link }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        url: link.url,
        expires_at: link.expires_at,
        account_id: accountId
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
