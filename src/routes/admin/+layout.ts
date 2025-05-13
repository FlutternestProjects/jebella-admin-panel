import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ url, parent }) => {
    const { supabase } = await parent();
    const { data: { session } } = await supabase.auth.getSession();

    // If trying to access login page while authenticated
    if (url.pathname === '/admin/login' && session) {
        // Check if user is admin
        const { data: userData } = await supabase
            .from('users')
            .select('user_type')
            .eq('id', session.user.id)
            .single();

        if (userData?.user_type === 'admin') {
            throw redirect(303, '/admin/dashboard');
        }
    }

    return {
        supabase
    };
}; 