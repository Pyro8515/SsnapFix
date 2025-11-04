import { createDbClient } from '../_shared/db.ts'
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createDbClient(req)
    
    // Get current user
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()
    if (authError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user record
    const { data: appUser, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('auth_user_id', authUser.id)
      .single()

    if (userError || !appUser) {
      return new Response(
        JSON.stringify({ error: 'User not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get professional profile if applicable
    let professionalProfile = null
    if (appUser.account_type === 'professional') {
      const { data: profile } = await supabase
        .from('professional_profiles')
        .select('*')
        .eq('user_id', appUser.id)
        .single()
      
      professionalProfile = profile
    }

    // Get document statuses
    const { data: documents } = await supabase
      .from('v_user_active_docs')
      .select('doc_type, doc_subtype, status, expires_at, reason')
      .eq('user_id', appUser.id)

    // Get trade compliance
    const { data: tradeCompliance } = await supabase
      .from('pro_trade_compliance')
      .select('trade, compliant, reason')
      .eq('user_id', appUser.id)

    const response = {
      id: appUser.id,
      account_type: appUser.account_type,
      active_role: appUser.active_role,
      can_switch_roles: appUser.can_switch_roles,
      verification_status: appUser.verification_status,
      avatar_url: appUser.avatar_url,
      professional_profile: professionalProfile ? {
        services: professionalProfile.services || [],
        identity_status: professionalProfile.identity_status,
        payouts_enabled: professionalProfile.payouts_enabled,
        payouts_status: professionalProfile.payouts_status
      } : undefined,
      documents: documents || [],
      trade_compliance: tradeCompliance || []
    }

    return new Response(
      JSON.stringify(response),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
