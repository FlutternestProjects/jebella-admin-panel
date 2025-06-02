<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';

    let loading = true;
    let saving = false;
    let error: string | null = null;
    let success: string | null = null;
    let user: any = null;
    let userEmails: any[] = [];
    let userPhones: any[] = [];
    let userAddresses: any[] = [];

    // Form data
    let profileForm = {
        name: '',
        gender: '',
        age: null as number | null
    };

    let phoneForm = {
        country_code: '+1',
        phone: '',
        label: '',
        is_primary: false
    };

    let addressForm = {
        name: '',
        label: '',
        line_1: '',
        line_2: '',
        city: '',
        state: '',
        postal_code: '',
        country: '',
        phone: '',
        is_default: false
    };

    let showPhoneForm = false;
    let showAddressForm = false;
    let editingPhoneId: string | null = null;
    let editingAddressId: string | null = null;

    onMount(async () => {
        await loadUserData();
        loading = false;
    });

    async function loadUserData() {
        try {
            const { data: { session } } = await supabase.auth.getSession();
            if (!session) return;

            // Load user data
            const { data: userData, error: userError } = await supabase
                .from('users')
                .select('*')
                .eq('id', session.user.id)
                .single();

            if (userError) throw userError;
            user = userData;

            // Populate form with user data
            profileForm = {
                name: user.name || '',
                gender: user.gender || '',
                age: user.age || null
            };

            // Load emails
            const { data: emailData, error: emailError } = await supabase
                .from('user_emails')
                .select('*')
                .eq('user_id', session.user.id)
                .eq('is_deleted', false)
                .order('is_primary', { ascending: false });

            if (!emailError) userEmails = emailData || [];

            // Load phone numbers
            const { data: phoneData, error: phoneError } = await supabase
                .from('user_phone_numbers')
                .select('*')
                .eq('user_id', session.user.id)
                .eq('is_deleted', false)
                .order('is_primary', { ascending: false });

            if (!phoneError) userPhones = phoneData || [];

            // Load addresses
            const { data: addressData, error: addressError } = await supabase
                .from('user_addresses')
                .select('*')
                .eq('user_id', session.user.id)
                .eq('is_deleted', false)
                .order('is_default', { ascending: false });

            if (!addressError) userAddresses = addressData || [];

        } catch (e: any) {
            error = e?.message || 'Failed to load profile data';
        }
    }

    async function handleProfileUpdate() {
        try {
            saving = true;
            error = null;
            success = null;

            const { data: { session } } = await supabase.auth.getSession();
            if (!session) return;

            const { error: updateError } = await supabase
                .from('users')
                .update({
                    name: profileForm.name,
                    gender: profileForm.gender || null,
                    age: profileForm.age || null
                })
                .eq('id', session.user.id);

            if (updateError) throw updateError;

            success = 'Profile updated successfully!';
            await loadUserData();

        } catch (e: any) {
            error = e?.message || 'Failed to update profile';
        } finally {
            saving = false;
        }
    }

    async function handlePhoneSubmit() {
        try {
            saving = true;
            error = null;

            const { data: { session } } = await supabase.auth.getSession();
            if (!session) return;

            if (editingPhoneId) {
                // Update existing phone
                const { error: updateError } = await supabase
                    .from('user_phone_numbers')
                    .update({
                        country_code: phoneForm.country_code,
                        phone: phoneForm.phone,
                        label: phoneForm.label,
                        is_primary: phoneForm.is_primary
                    })
                    .eq('id', editingPhoneId);

                if (updateError) throw updateError;
            } else {
                // Add new phone
                const { error: insertError } = await supabase
                    .from('user_phone_numbers')
                    .insert({
                        user_id: session.user.id,
                        country_code: phoneForm.country_code,
                        phone: phoneForm.phone,
                        label: phoneForm.label,
                        is_primary: phoneForm.is_primary
                    });

                if (insertError) throw insertError;
            }

            showPhoneForm = false;
            editingPhoneId = null;
            phoneForm = { country_code: '+1', phone: '', label: '', is_primary: false };
            await loadUserData();

        } catch (e: any) {
            error = e?.message || 'Failed to save phone number';
        } finally {
            saving = false;
        }
    }

    async function handleAddressSubmit() {
        try {
            saving = true;
            error = null;

            const { data: { session } } = await supabase.auth.getSession();
            if (!session) return;

            if (editingAddressId) {
                // Update existing address
                const { error: updateError } = await supabase
                    .from('user_addresses')
                    .update(addressForm)
                    .eq('id', editingAddressId);

                if (updateError) throw updateError;
            } else {
                // Add new address
                const { error: insertError } = await supabase
                    .from('user_addresses')
                    .insert({
                        user_id: session.user.id,
                        ...addressForm
                    });

                if (insertError) throw insertError;
            }

            showAddressForm = false;
            editingAddressId = null;
            addressForm = {
                name: '', label: '', line_1: '', line_2: '', city: '', 
                state: '', postal_code: '', country: '', phone: '', is_default: false
            };
            await loadUserData();

        } catch (e: any) {
            error = e?.message || 'Failed to save address';
        } finally {
            saving = false;
        }
    }

    async function deletePhone(id: string) {
        if (!confirm('Are you sure you want to delete this phone number?')) return;

        try {
            const { error } = await supabase
                .from('user_phone_numbers')
                .update({ is_deleted: true })
                .eq('id', id);

            if (error) throw error;
            await loadUserData();
        } catch (e: any) {
            error = e?.message || 'Failed to delete phone number';
        }
    }

    function editPhone(phone: any) {
        phoneForm = {
            country_code: phone.country_code,
            phone: phone.phone,
            label: phone.label,
            is_primary: phone.is_primary
        };
        editingPhoneId = phone.id;
        showPhoneForm = true;
    }

    function editAddress(address: any) {
        addressForm = { ...address };
        editingAddressId = address.id;
        showAddressForm = true;
    }

    async function deleteAddress(id: string) {
        if (!confirm('Are you sure you want to delete this address?')) return;

        try {
            const { error } = await supabase
                .from('user_addresses')
                .update({ is_deleted: true })
                .eq('id', id);

            if (error) throw error;
            await loadUserData();
        } catch (e: any) {
            error = e?.message || 'Failed to delete address';
        }
    }

    function cancelPhoneForm() {
        showPhoneForm = false;
        editingPhoneId = null;
        phoneForm = { country_code: '+1', phone: '', label: '', is_primary: false };
    }

    function cancelAddressForm() {
        showAddressForm = false;
        editingAddressId = null;
        addressForm = {
            name: '', label: '', line_1: '', line_2: '', city: '', 
            state: '', postal_code: '', country: '', phone: '', is_default: false
        };
    }
</script>

{#if loading}
    <div class="loading">Loading profile...</div>
{:else}
    <div class="profile-container">
        <header class="content-header">
            <h2>My Profile</h2>
        </header>

        {#if error}
            <div class="error-message">{error}</div>
        {/if}

        {#if success}
            <div class="success-message">{success}</div>
        {/if}

        <!-- Basic Profile Information -->
        <div class="profile-section">
            <h3>Basic Information</h3>
            <form on:submit|preventDefault={handleProfileUpdate} class="profile-form">
                <div class="form-group">
                    <label for="name">Full Name</label>
                    <input
                        type="text"
                        id="name"
                        bind:value={profileForm.name}
                        placeholder="Enter your full name"
                        required
                    />
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label for="gender">Gender</label>
                        <select id="gender" bind:value={profileForm.gender}>
                            <option value="">Select Gender</option>
                            <option value="male">Male</option>
                            <option value="female">Female</option>
                            <option value="other">Other</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="age">Age</label>
                        <input
                            type="number"
                            id="age"
                            bind:value={profileForm.age}
                            placeholder="Enter your age"
                            min="18"
                            max="120"
                        />
                    </div>
                </div>

                <button type="submit" class="submit-button" disabled={saving}>
                    {#if saving}
                        <span class="loading-spinner"></span>
                    {:else}
                        Update Profile
                    {/if}
                </button>
            </form>
        </div>

        <!-- Email Addresses -->
        <div class="profile-section">
            <div class="section-header">
                <h3>Email Address</h3>
                <span class="read-only-badge">Read Only</span>
            </div>

            <div class="items-list">
                {#each userEmails as email}
                    <div class="item-card read-only-card">
                        <div class="item-info">
                            <span class="item-value">{email.email}</span>
                            {#if email.is_primary}
                                <span class="primary-badge">Primary</span>
                            {/if}
                        </div>
                        <div class="item-note">
                            <span class="note-text">This is your login email and cannot be changed here.</span>
                        </div>
                    </div>
                {/each}
                {#if userEmails.length === 0}
                    <p class="empty-message">No email address found.</p>
                {/if}
            </div>
        </div>

        <!-- Phone Numbers -->
        <div class="profile-section">
            <div class="section-header">
                <h3>Phone Numbers</h3>
                <button class="add-button" on:click={() => showPhoneForm = true}>
                    Add Phone
                </button>
            </div>

            {#if showPhoneForm}
                <div class="form-container">
                    <h4>{editingPhoneId ? 'Edit' : 'Add'} Phone Number</h4>
                    <form on:submit|preventDefault={handlePhoneSubmit}>
                        <div class="form-row">
                            <div class="form-group">
                                <label for="country_code">Country Code</label>
                                <input
                                    type="text"
                                    id="country_code"
                                    bind:value={phoneForm.country_code}
                                    placeholder="+1"
                                    required
                                />
                            </div>

                            <div class="form-group">
                                <label for="phone">Phone Number</label>
                                <input
                                    type="tel"
                                    id="phone"
                                    bind:value={phoneForm.phone}
                                    placeholder="1234567890"
                                    required
                                />
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="phone_label">Label (Optional)</label>
                            <input
                                type="text"
                                id="phone_label"
                                bind:value={phoneForm.label}
                                placeholder="e.g., Work, Home, Mobile"
                            />
                        </div>

                        <div class="form-group">
                            <label class="checkbox-label">
                                <input
                                    type="checkbox"
                                    bind:checked={phoneForm.is_primary}
                                />
                                Set as primary phone
                            </label>
                        </div>

                        <div class="form-actions">
                            <button type="button" class="cancel-button" on:click={cancelPhoneForm}>
                                Cancel
                            </button>
                            <button type="submit" class="submit-button" disabled={saving}>
                                {editingPhoneId ? 'Update' : 'Add'} Phone
                            </button>
                        </div>
                    </form>
                </div>
            {/if}

            <div class="items-list">
                {#each userPhones as phone}
                    <div class="item-card">
                        <div class="item-info">
                            <span class="item-value">{phone.country_code} {phone.phone}</span>
                            {#if phone.label}
                                <span class="item-label">{phone.label}</span>
                            {/if}
                            {#if phone.is_primary}
                                <span class="primary-badge">Primary</span>
                            {/if}
                        </div>
                        <div class="item-actions">
                            <button class="edit-button" on:click={() => editPhone(phone)}>
                                Edit
                            </button>
                            <button class="delete-button" on:click={() => deletePhone(phone.id)}>
                                Delete
                            </button>
                        </div>
                    </div>
                {/each}
                {#if userPhones.length === 0}
                    <p class="empty-message">No phone numbers added yet.</p>
                {/if}
            </div>
        </div>

        <!-- Addresses -->
        <div class="profile-section">
            <div class="section-header">
                <h3>Addresses</h3>
                <button class="add-button" on:click={() => showAddressForm = true}>
                    Add Address
                </button>
            </div>

            {#if showAddressForm}
                <div class="form-container">
                    <h4>{editingAddressId ? 'Edit' : 'Add'} Address</h4>
                    <form on:submit|preventDefault={handleAddressSubmit}>
                        <div class="form-row">
                            <div class="form-group">
                                <label for="address_name">Name</label>
                                <input
                                    type="text"
                                    id="address_name"
                                    bind:value={addressForm.name}
                                    placeholder="e.g., John Doe"
                                />
                            </div>

                            <div class="form-group">
                                <label for="address_label">Label</label>
                                <input
                                    type="text"
                                    id="address_label"
                                    bind:value={addressForm.label}
                                    placeholder="e.g., Home, Office"
                                />
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="line_1">Address Line 1</label>
                            <input
                                type="text"
                                id="line_1"
                                bind:value={addressForm.line_1}
                                placeholder="Street address"
                                required
                            />
                        </div>

                        <div class="form-group">
                            <label for="line_2">Address Line 2 (Optional)</label>
                            <input
                                type="text"
                                id="line_2"
                                bind:value={addressForm.line_2}
                                placeholder="Apartment, suite, etc."
                            />
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="city">City</label>
                                <input
                                    type="text"
                                    id="city"
                                    bind:value={addressForm.city}
                                    required
                                />
                            </div>

                            <div class="form-group">
                                <label for="state">State/Province</label>
                                <input
                                    type="text"
                                    id="state"
                                    bind:value={addressForm.state}
                                />
                            </div>
                        </div>

                        <div class="form-row">
                            <div class="form-group">
                                <label for="postal_code">Postal Code</label>
                                <input
                                    type="text"
                                    id="postal_code"
                                    bind:value={addressForm.postal_code}
                                    required
                                />
                            </div>

                            <div class="form-group">
                                <label for="country">Country</label>
                                <input
                                    type="text"
                                    id="country"
                                    bind:value={addressForm.country}
                                    required
                                />
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="address_phone">Phone (Optional)</label>
                            <input
                                type="tel"
                                id="address_phone"
                                bind:value={addressForm.phone}
                                placeholder="Phone number for this address"
                            />
                        </div>

                        <div class="form-group">
                            <label class="checkbox-label">
                                <input
                                    type="checkbox"
                                    bind:checked={addressForm.is_default}
                                />
                                Set as default address
                            </label>
                        </div>

                        <div class="form-actions">
                            <button type="button" class="cancel-button" on:click={cancelAddressForm}>
                                Cancel
                            </button>
                            <button type="submit" class="submit-button" disabled={saving}>
                                {editingAddressId ? 'Update' : 'Add'} Address
                            </button>
                        </div>
                    </form>
                </div>
            {/if}

            <div class="items-list">
                {#each userAddresses as address}
                    <div class="item-card address-card">
                        <div class="item-info">
                            <div class="address-header">
                                {#if address.name}
                                    <span class="address-name">{address.name}</span>
                                {/if}
                                {#if address.label}
                                    <span class="item-label">{address.label}</span>
                                {/if}
                                {#if address.is_default}
                                    <span class="primary-badge">Default</span>
                                {/if}
                            </div>
                            <div class="address-details">
                                <p>{address.line_1}</p>
                                {#if address.line_2}
                                    <p>{address.line_2}</p>
                                {/if}
                                <p>{address.city}, {address.state} {address.postal_code}</p>
                                <p>{address.country}</p>
                                {#if address.phone}
                                    <p>📞 {address.phone}</p>
                                {/if}
                            </div>
                        </div>
                        <div class="item-actions">
                            <button class="edit-button" on:click={() => editAddress(address)}>
                                Edit
                            </button>
                            <button class="delete-button" on:click={() => deleteAddress(address.id)}>
                                Delete
                            </button>
                        </div>
                    </div>
                {/each}
                {#if userAddresses.length === 0}
                    <p class="empty-message">No addresses added yet.</p>
                {/if}
            </div>
        </div>
    </div>
{/if}

<style>
    .profile-container {
        padding: 2rem;
        max-width: 1000px;
        margin: 0 auto;
    }

    .content-header {
        margin-bottom: 2rem;
    }

    .content-header h2 {
        color: #2d3748;
        font-size: 2rem;
        margin: 0;
    }

    .profile-section {
        background: white;
        border-radius: 12px;
        padding: 2rem;
        margin-bottom: 2rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    }

    .profile-section h3 {
        color: #2d3748;
        font-size: 1.5rem;
        margin: 0 0 1.5rem 0;
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.5rem;
    }

    .section-header h3 {
        margin: 0;
    }

    .add-button {
        padding: 0.5rem 1rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.875rem;
        transition: background 0.2s;
    }

    .add-button:hover {
        background: #3182ce;
    }

    .read-only-badge {
        background: #edf2f7;
        color: #4a5568;
        padding: 0.25rem 0.75rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 500;
    }

    .form-container {
        background: #f7fafc;
        border-radius: 8px;
        padding: 1.5rem;
        margin-bottom: 1.5rem;
    }

    .form-container h4 {
        margin: 0 0 1rem 0;
        color: #2d3748;
    }

    .profile-form {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .form-group {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    .form-group label {
        color: #4a5568;
        font-weight: 500;
        font-size: 0.875rem;
    }

    .form-group input,
    .form-group select {
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
        transition: border-color 0.2s;
    }

    .form-group input:focus,
    .form-group select:focus {
        outline: none;
        border-color: #4299e1;
    }

    .form-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    .checkbox-label {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        color: #4a5568;
        cursor: pointer;
    }

    .checkbox-label input[type="checkbox"] {
        width: auto;
        margin: 0;
    }

    .form-actions {
        display: flex;
        gap: 1rem;
        justify-content: flex-end;
        margin-top: 1rem;
    }

    .submit-button,
    .cancel-button {
        padding: 0.75rem 1.5rem;
        border-radius: 6px;
        cursor: pointer;
        font-size: 0.875rem;
        transition: all 0.2s;
    }

    .submit-button {
        background: #4299e1;
        color: white;
        border: none;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .submit-button:hover {
        background: #3182ce;
    }

    .submit-button:disabled {
        opacity: 0.6;
        cursor: not-allowed;
    }

    .cancel-button {
        background: white;
        color: #4a5568;
        border: 2px solid #e2e8f0;
    }

    .cancel-button:hover {
        background: #f7fafc;
    }

    .items-list {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .item-card {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem;
        border: 2px solid #e2e8f0;
        border-radius: 8px;
        background: white;
    }

    .address-card {
        align-items: flex-start;
    }

    .read-only-card {
        background: #f7fafc;
        border-color: #e2e8f0;
        opacity: 0.9;
    }

    .item-info {
        flex: 1;
    }

    .item-note {
        display: flex;
        align-items: center;
    }

    .note-text {
        font-size: 0.75rem;
        color: #718096;
        font-style: italic;
    }

    .item-value {
        font-weight: 500;
        color: #2d3748;
    }

    .item-label {
        display: inline-block;
        background: #edf2f7;
        color: #4a5568;
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
        font-size: 0.75rem;
        margin-left: 0.5rem;
    }

    .primary-badge {
        display: inline-block;
        background: #4299e1;
        color: white;
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
        font-size: 0.75rem;
        margin-left: 0.5rem;
    }

    .address-header {
        margin-bottom: 0.5rem;
    }

    .address-name {
        font-weight: 600;
        color: #2d3748;
    }

    .address-details p {
        margin: 0.25rem 0;
        color: #4a5568;
        font-size: 0.875rem;
    }

    .item-actions {
        display: flex;
        gap: 0.5rem;
    }

    .edit-button,
    .delete-button {
        padding: 0.5rem 1rem;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.75rem;
        transition: all 0.2s;
    }

    .edit-button {
        background: #4299e1;
        color: white;
        border: none;
    }

    .edit-button:hover {
        background: #3182ce;
    }

    .delete-button {
        background: #e53e3e;
        color: white;
        border: none;
    }

    .delete-button:hover {
        background: #c53030;
    }

    .empty-message {
        color: #a0aec0;
        font-style: italic;
        text-align: center;
        padding: 2rem;
    }

    .loading {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 50vh;
        font-size: 1.2rem;
        color: #4a5568;
    }

    .error-message {
        background: #fed7d7;
        border: 1px solid #feb2b2;
        color: #c53030;
        padding: 1rem;
        border-radius: 6px;
        margin-bottom: 1rem;
    }

    .success-message {
        background: #c6f6d5;
        border: 1px solid #9ae6b4;
        color: #2f855a;
        padding: 1rem;
        border-radius: 6px;
        margin-bottom: 1rem;
    }

    .loading-spinner {
        display: inline-block;
        width: 1rem;
        height: 1rem;
        border: 2px solid #ffffff;
        border-radius: 50%;
        border-top-color: transparent;
        animation: spin 1s ease-in-out infinite;
    }

    @keyframes spin {
        to { transform: rotate(360deg); }
    }

    @media (max-width: 768px) {
        .profile-container {
            padding: 1rem;
        }

        .form-row {
            grid-template-columns: 1fr;
        }

        .item-card {
            flex-direction: column;
            align-items: flex-start;
            gap: 1rem;
        }

        .item-actions {
            align-self: flex-end;
        }
    }
</style> 