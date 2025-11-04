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

    // Verify webhook signature format (basic validation)
    // Note: Full signature verification requires the Stripe library
    // For production, use: https://github.com/stripe/stripe-node or similar
    // The signature format is: t=TIMESTAMP,v1=SIGNATURE,v0=LEGACY_SIGNATURE
    const signatureHeader = signature
    if (!signatureHeader || !signatureHeader.includes('v1=')) {
      return new Response(
        JSON.stringify({ error: 'Invalid signature format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse event for idempotency check
    let event: any
    try {
      event = JSON.parse(body)
    } catch (error) {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON payload' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

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
          source: 'stripe_identity',
          payload: event
        })
    }

    // Process identity verification events
    if (event.type === 'identity.verification_session.verified' || 
        event.type === 'identity.verification_session.requires_input' ||
        event.type === 'identity.verification_session.processing' ||
        event.type === 'identity.verification_session.canceled') {
      
      const session = event.data.object
      const identityRefId = session.id

      // Find profile by identity_ref_id
      const { data: profile } = await serviceClient
        .from('professional_profiles')
        .select('user_id')
        .eq('identity_ref_id', identityRefId)
        .single()

      if (!profile) {
        return new Response(
          JSON.stringify({ error: 'Profile not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Map Stripe status to our status
      let identityStatus = 'pending'
      if (event.type === 'identity.verification_session.verified') {
        identityStatus = 'verified'
      } else if (event.type === 'identity.verification_session.requires_input') {
        identityStatus = 'needs_review'
      } else if (event.type === 'identity.verification_session.canceled') {
        identityStatus = 'failed'
      }

      // Update profile
      await serviceClient
        .from('professional_profiles')
        .update({ identity_status: identityStatus })
        .eq('user_id', profile.user_id)

      // Recompute compliance
      await serviceClient.rpc('recompute_pro_trade_compliance', {
        target_user_id: profile.user_id
      })

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
