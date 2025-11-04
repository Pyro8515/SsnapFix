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

    const { file_url, doc_type, doc_subtype, number, issuer, issued_at, expires_at } = await req.json()
    
    if (!file_url || !doc_type) {
      return new Response(
        JSON.stringify({ error: 'file_url and doc_type are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
        JSON.stringify({ error: 'Only professionals can submit documents' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Upsert document (using unique constraint to handle conflicts)
    const { data: document, error: docError } = await serviceClient
      .from('pro_documents')
      .upsert({
        user_id: appUser.id,
        doc_type,
        doc_subtype: doc_subtype || null,
        file_url,
        number: number || null,
        issuer: issuer || null,
        issued_at: issued_at || null,
        expires_at: expires_at || null,
        status: 'pending'
      }, {
        onConflict: 'user_id,doc_type,COALESCE(doc_subtype,\'\')'
      })
      .select()
      .single()

    if (docError) {
      return new Response(
        JSON.stringify({ error: 'Failed to save document', details: docError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Recompute compliance
    await serviceClient.rpc('recompute_pro_trade_compliance', {
      target_user_id: appUser.id
    })

    // Write audit log (could be enhanced)
    // For now, we'll just return success

    return new Response(
      JSON.stringify({
        id: document.id,
        status: document.status,
        message: 'Document submitted successfully'
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
