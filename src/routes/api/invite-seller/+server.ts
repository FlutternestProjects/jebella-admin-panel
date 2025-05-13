import { json } from '@sveltejs/kit';
import { createClient } from '@supabase/supabase-js';

export async function POST({ request }) {
    try {
        const { email } = await request.json();

        // Create a Supabase client with the service role key
        const supabaseAdmin = createClient(
            import.meta.env.VITE_SUPABASE_URL,
            import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY
        );

        // Invite user by email
        const { data, error } = await supabaseAdmin.auth.admin.inviteUserByEmail(
            email,
            {
                redirectTo: `${request.headers.get('origin')}/reset-password`
            }
        );

        if (error) throw error;

        return json({ success: true, data });
    } catch (error: any) {
        return json({ success: false, error: error.message }, { status: 400 });
    }
} 