import { createDbClient } from '../_shared/db.ts'
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
    
    const { data: { user: authUser }, error: authError } = await supabase.auth.getUser()
    if (authError || !authUser) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get app user
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

    // Check if user can switch roles
    if (!appUser.can_switch_roles) {
      return new Response(
        JSON.stringify({ error: 'Role switching not allowed for this account' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Determine new role (toggle between customer and professional)
    const newRole = appUser.active_role === 'customer' ? 'professional' : 'customer'

    // Validate eligibility (if switching to professional, must have verified profile)
    if (newRole === 'professional' && appUser.account_type === 'professional') {
      const { data: profile } = await supabase
        .from('professional_profiles')
        .select('identity_status')
        .eq('user_id', appUser.id)
        .single()

      if (!profile || profile.identity_status !== 'verified') {
        return new Response(
          JSON.stringify({ error: 'Cannot switch to professional role: identity not verified' }),
          { status: 409, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Update role
    const { data: updatedUser, error: updateError } = await supabase
      .from('users')
      .update({ active_role: newRole })
      .eq('id', appUser.id)
      .select('active_role')
      .single()

    if (updateError) {
      return new Response(
        JSON.stringify({ error: updateError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ active_role: updatedUser.active_role }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
