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
        JSON.stringify({ error: 'Only professionals can start identity verification' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get or create professional profile
    let { data: profile } = await supabase
      .from('professional_profiles')
      .select('*')
      .eq('user_id', appUser.id)
      .single()

    if (!profile) {
      const { data: newProfile } = await serviceClient
        .from('professional_profiles')
        .insert({ user_id: appUser.id })
        .select()
        .single()
      profile = newProfile
    }

    // Initialize Stripe Identity session
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY')
    if (!stripeSecretKey) {
      return new Response(
        JSON.stringify({ error: 'Stripe not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const returnUrl = Deno.env.get('STRIPE_IDENTITY_RETURN_URL') || 'https://your-app.com/identity-return'
    
    const response = await fetch('https://api.stripe.com/v1/identity/verification_sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        type: 'document',
        return_url: returnUrl,
        metadata: JSON.stringify({ user_id: appUser.id, auth_user_id: authUser.id })
      })
    })

    const session = await response.json()

    if (!response.ok) {
      return new Response(
        JSON.stringify({ error: 'Failed to create Stripe Identity session', details: session }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update profile with identity_ref_id
    await serviceClient
      .from('professional_profiles')
      .update({
        identity_ref_id: session.id,
        identity_status: 'pending'
      })
      .eq('user_id', appUser.id)

    return new Response(
      JSON.stringify({
        verification_session_id: session.id,
        client_secret: session.client_secret,
        url: session.url
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
