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

    const { temp_path, final_path } = await req.json()
    if (!temp_path || !final_path) {
      return new Response(
        JSON.stringify({ error: 'temp_path and final_path are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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

    // Verify temp_path belongs to user
    if (!temp_path.startsWith(`avatars-temp/${appUser.id}/`)) {
      return new Response(
        JSON.stringify({ error: 'Invalid temp path' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify final_path belongs to user
    if (!final_path.startsWith(`pro-avatars/${appUser.id}/`)) {
      return new Response(
        JSON.stringify({ error: 'Invalid final path' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if temp file exists
    const tempDir = temp_path.split('/').slice(0, -1).join('/')
    const tempFileName = temp_path.split('/').pop()
    const { data: tempFile, error: tempError } = await serviceClient.storage
      .from('pro-avatars')
      .list(tempDir, {
        search: tempFileName
      })

    if (tempError || !tempFile || tempFile.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Temp file not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Download temp file
    const { data: fileData, error: downloadError } = await serviceClient.storage
      .from('pro-avatars')
      .download(temp_path)

    if (downloadError || !fileData) {
      return new Response(
        JSON.stringify({ error: 'Failed to download temp file', details: downloadError?.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Upload to final path (public bucket)
    const { error: uploadError } = await serviceClient.storage
      .from('pro-avatars')
      .upload(final_path, fileData, {
        upsert: true, // Overwrite existing avatar
        contentType: fileData.type || 'image/jpeg'
      })

    if (uploadError) {
      return new Response(
        JSON.stringify({ error: 'Failed to move avatar to public path', details: uploadError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Delete temp file
    await serviceClient.storage
      .from('pro-avatars')
      .remove([temp_path])

    // Get public URL
    const { data: publicUrlData } = serviceClient.storage
      .from('pro-avatars')
      .getPublicUrl(final_path)

    // Update user avatar_url
    const { error: updateError } = await serviceClient
      .from('users')
      .update({ avatar_url: publicUrlData.publicUrl })
      .eq('id', appUser.id)

    if (updateError) {
      return new Response(
        JSON.stringify({ error: 'Failed to update avatar URL', details: updateError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        avatar_url: publicUrlData.publicUrl,
        message: 'Avatar approved and moved to public path'
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

