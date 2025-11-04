import { createServiceClient } from '../_shared/db.ts'
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
    const serviceClient = createServiceClient()
    const stripeWebhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')
    
    if (!stripeWebhookSecret) {
      return new Response(
        JSON.stringify({ error: 'Webhook secret not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const signature = req.headers.get('stripe-signature')
    if (!signature) {
      return new Response(
        JSON.stringify({ error: 'Missing signature' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.text()
    const event = JSON.parse(body)

    // Check idempotency
    const { data: existing } = await serviceClient
      .from('webhook_events')
      .select('id, processed')
      .eq('event_id', event.id)
      .single()

    if (existing) {
      if (existing.processed) {
        return new Response(
          JSON.stringify({ message: 'Event already processed' }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    } else {
      // Log new event
      await serviceClient
        .from('webhook_events')
        .insert({
          event_id: event.id,
          event_type: event.type,
          source: 'stripe_payments',
          payload: event
        })
    }

    // Process Connect account events
    if (event.type === 'account.updated' || 
        event.type === 'account.application.deauthorized') {
      
      const account = event.data.object
      const stripeAccountId = account.id

      // Find profile by stripe_account_id
      const { data: profile } = await serviceClient
        .from('professional_profiles')
        .select('user_id')
        .eq('stripe_account_id', stripeAccountId)
        .single()

      if (!profile) {
        return new Response(
          JSON.stringify({ error: 'Profile not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Map Stripe account status
      let payoutsStatus = 'pending'
      let payoutsEnabled = false

      if (account.details_submitted && account.payouts_enabled) {
        payoutsStatus = 'active'
        payoutsEnabled = true
      } else if (account.charges_enabled === false) {
        payoutsStatus = 'restricted'
      } else if (account.payouts_enabled === false) {
        payoutsStatus = 'pending'
      }

      // Update profile
      await serviceClient
        .from('professional_profiles')
        .update({
          payouts_enabled: payoutsEnabled,
          payouts_status: payoutsStatus
        })
        .eq('user_id', profile.user_id)

      // Mark event as processed
      await serviceClient
        .from('webhook_events')
        .update({ processed: true })
        .eq('event_id', event.id)
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
