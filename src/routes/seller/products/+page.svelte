<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabase';
    import { selectedShop } from '$lib/stores/selectedShop';
    import { goto } from '$app/navigation';

    let loading = true;
    let brands: any[] = [];
    let categories: any[] = [];
    let subcategories: any[] = [];
    let colors: any[] = [];
    let sizes: any[] = [];
    let audiences: any[] = [];
    let selectedCategory: string | null = null;
    let showForm = false;
    let products: any[] = [];

    // Form data
    let productForm = {
        title: '',
        sub_title: '',
        description: '',
        brand_id: null as string | null,
        category_id: null as string | null,
        subcategory_id: null as string | null,
        audiences: [] as string[],
        variants: [{
            name: '',
            sku: '',
            size_id: null as string | null,
            color_id: null as string | null,
            price: 0,
            discount_price: null as number | null,
            condition: 'new',
            status: 'active'
        }]
    };

    onMount(async () => {
        await Promise.all([
            loadBrands(),
            loadCategories(),
            loadColors(),
            loadSizes(),
            loadAudiences(),
            loadProducts()
        ]);
        loading = false;
    });

    async function loadBrands() {
        const { data, error } = await supabase
            .from('brands')
            .select('*')
            .eq('is_deleted', false);
        if (!error && data) brands = data;
    }

    async function loadCategories() {
        const { data, error } = await supabase
            .from('categories')
            .select('*')
            .eq('is_deleted', false);
        if (!error && data) categories = data;
    }

    async function loadSubcategories() {
        if (!selectedCategory) return;
        const { data, error } = await supabase
            .from('subcategories')
            .select('*')
            .eq('category_id', selectedCategory)
            .eq('is_deleted', false);
        if (!error && data) subcategories = data;
    }

    async function loadColors() {
        const { data, error } = await supabase
            .from('colors')
            .select('*')
            .eq('is_deleted', false)
            .eq('is_active', true);
        if (!error && data) colors = data;
    }

    async function loadSizes() {
        const { data, error } = await supabase
            .from('sizes')
            .select('*')
            .eq('is_deleted', false)
            .eq('is_active', true);
        if (!error && data) sizes = data;
    }

    async function loadAudiences() {
        const { data, error } = await supabase
            .from('audiences')
            .select('*')
            .eq('is_deleted', false);
        if (!error && data) audiences = data;
    }

    async function loadProducts() {
        try {
            const selectedShopId = $selectedShop;
            if (!selectedShopId) {
                loading = false;
                return;
            }

            // Get products with their details
            const { data, error } = await supabase
                .from('products')
                .select(`
                    *,
                    brand:brands (name),
                    category:categories (name),
                    subcategory:subcategories (name),
                    variants:product_variants (
                        id,
                        name,
                        sku,
                        price,
                        discount_price,
                        status,
                        size:sizes (label),
                        color:colors (name, hex_code)
                    )
                `)
                .eq('shop_id', selectedShopId)
                .eq('is_deleted', false)
                .order('created_at', { ascending: false });

            if (!error && data) {
                products = data;
            }

        } catch (e) {
            console.error('Error:', e);
        } finally {
            loading = false;
        }
    }

    function addVariant() {
        productForm.variants = [...productForm.variants, {
            name: '',
            sku: '',
            size_id: null,
            color_id: null,
            price: 0,
            discount_price: null,
            condition: 'new',
            status: 'active'
        }];
    }

    function removeVariant(index: number) {
        productForm.variants = productForm.variants.filter((_, i) => i !== index);
    }

    async function handleSubmit() {
        try {
            if (!$selectedShop) {
                alert('Please select a shop first');
                return;
            }

            const { data: { session } } = await supabase.auth.getSession();
            if (!session) {
                goto('/seller/login');
                return;
            }

            // Insert product
            const { data: productData, error: productError } = await supabase
                .from('products')
                .insert({
                    title: productForm.title,
                    sub_title: productForm.sub_title,
                    description: productForm.description,
                    brand_id: productForm.brand_id,
                    category_id: productForm.category_id,
                    subcategory_id: productForm.subcategory_id,
                    seller_id: session.user.id
                })
                .select()
                .single();

            if (productError) throw productError;

            // Insert product audiences
            if (productForm.audiences.length > 0) {
                const audienceData = productForm.audiences.map(audienceId => ({
                    product_id: productData.id,
                    audience_id: audienceId
                }));

                const { error: audienceError } = await supabase
                    .from('product_audiences')
                    .insert(audienceData);

                if (audienceError) throw audienceError;
            }

            // Insert product variants
            const variantsData = productForm.variants.map(variant => ({
                ...variant,
                product_id: productData.id
            }));

            const { error: variantError } = await supabase
                .from('product_variants')
                .insert(variantsData);

            if (variantError) throw variantError;

            // Reset form and show success message
            alert('Product added successfully!');
            resetForm();

        } catch (error: any) {
            console.error('Error adding product:', error);
            alert(error.message || 'An error occurred while adding the product');
        }
    }

    function resetForm() {
        productForm = {
            title: '',
            sub_title: '',
            description: '',
            brand_id: null,
            category_id: null,
            subcategory_id: null,
            audiences: [],
            variants: [{
                name: '',
                sku: '',
                size_id: null,
                color_id: null,
                price: 0,
                discount_price: null,
                condition: 'new',
                status: 'active'
            }]
        };
        showForm = false;
    }

    $: {
        if (productForm.category_id !== selectedCategory) {
            selectedCategory = productForm.category_id;
            productForm.subcategory_id = null;
            loadSubcategories();
        }
    }
</script>

{#if loading}
    <div class="loading">Loading...</div>
{:else if !$selectedShop}
    <div class="setup-shop">
        <h3>Select or Create a Shop</h3>
        <p>You need to select or create a shop to manage products</p>
        <a href="/seller/shops" class="setup-button">Manage Shops</a>
    </div>
{:else}
    <div class="products-container">
        <header class="content-header">
            <h2>Products</h2>
            <button class="add-button" on:click={() => showForm = true}>
                Add New Product
            </button>
        </header>

        {#if showForm}
            <div class="form-overlay">
                <div class="form-container">
                    <h2>Add New Product</h2>
                    <form on:submit|preventDefault={handleSubmit}>
                        <!-- Basic Product Information -->
                        <div class="form-section">
                            <h3>Basic Information</h3>
                            <div class="form-group">
                                <label for="title">Title *</label>
                                <input
                                    type="text"
                                    id="title"
                                    bind:value={productForm.title}
                                    required
                                />
                            </div>

                            <div class="form-group">
                                <label for="sub_title">Subtitle</label>
                                <input
                                    type="text"
                                    id="sub_title"
                                    bind:value={productForm.sub_title}
                                />
                            </div>

                            <div class="form-group">
                                <label for="description">Description</label>
                                <textarea
                                    id="description"
                                    bind:value={productForm.description}
                                    rows="4"
                                ></textarea>
                            </div>
                        </div>

                        <!-- Categories and Brand -->
                        <div class="form-section">
                            <h3>Classification</h3>
                            <div class="form-group">
                                <label for="brand">Brand</label>
                                <select id="brand" bind:value={productForm.brand_id}>
                                    <option value={null}>Select Brand</option>
                                    {#each brands as brand}
                                        <option value={brand.id}>{brand.name}</option>
                                    {/each}
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="category">Category *</label>
                                <select id="category" bind:value={productForm.category_id} required>
                                    <option value={null}>Select Category</option>
                                    {#each categories as category}
                                        <option value={category.id}>{category.name}</option>
                                    {/each}
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="subcategory">Subcategory *</label>
                                <select id="subcategory" bind:value={productForm.subcategory_id} required>
                                    <option value={null}>Select Subcategory</option>
                                    {#each subcategories as subcategory}
                                        <option value={subcategory.id}>{subcategory.name}</option>
                                    {/each}
                                </select>
                            </div>

                            <div class="form-group">
                                <label>Target Audience</label>
                                <div class="checkbox-group">
                                    {#each audiences as audience}
                                        <label class="checkbox-label">
                                            <input
                                                type="checkbox"
                                                value={audience.id}
                                                bind:group={productForm.audiences}
                                            />
                                            {audience.name}
                                        </label>
                                    {/each}
                                </div>
                            </div>
                        </div>

                        <!-- Product Variants -->
                        <div class="form-section">
                            <div class="section-header">
                                <h3>Product Variants</h3>
                                <button type="button" class="add-variant-button" on:click={addVariant}>
                                    Add Variant
                                </button>
                            </div>

                            {#each productForm.variants as variant, i}
                                <div class="variant-container">
                                    <div class="variant-header">
                                        <h4>Variant {i + 1}</h4>
                                        {#if i > 0}
                                            <button type="button" class="remove-variant-button" on:click={() => removeVariant(i)}>
                                                Remove
                                            </button>
                                        {/if}
                                    </div>

                                    <div class="form-group">
                                        <label for="variant-name-{i}">Variant Name *</label>
                                        <input
                                            type="text"
                                            id="variant-name-{i}"
                                            bind:value={variant.name}
                                            required
                                        />
                                    </div>

                                    <div class="form-group">
                                        <label for="variant-sku-{i}">SKU *</label>
                                        <input
                                            type="text"
                                            id="variant-sku-{i}"
                                            bind:value={variant.sku}
                                            required
                                        />
                                    </div>

                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="variant-size-{i}">Size</label>
                                            <select id="variant-size-{i}" bind:value={variant.size_id}>
                                                <option value={null}>Select Size</option>
                                                {#each sizes as size}
                                                    <option value={size.id}>{size.label}</option>
                                                {/each}
                                            </select>
                                        </div>

                                        <div class="form-group">
                                            <label for="variant-color-{i}">Color</label>
                                            <select id="variant-color-{i}" bind:value={variant.color_id}>
                                                <option value={null}>Select Color</option>
                                                {#each colors as color}
                                                    <option value={color.id}>{color.name}</option>
                                                {/each}
                                            </select>
                                        </div>
                                    </div>

                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="variant-price-{i}">Price *</label>
                                            <input
                                                type="number"
                                                id="variant-price-{i}"
                                                bind:value={variant.price}
                                                min="0"
                                                step="0.01"
                                                required
                                            />
                                        </div>

                                        <div class="form-group">
                                            <label for="variant-discount-{i}">Discount Price</label>
                                            <input
                                                type="number"
                                                id="variant-discount-{i}"
                                                bind:value={variant.discount_price}
                                                min="0"
                                                step="0.01"
                                            />
                                        </div>
                                    </div>

                                    <div class="form-row">
                                        <div class="form-group">
                                            <label for="variant-condition-{i}">Condition *</label>
                                            <select id="variant-condition-{i}" bind:value={variant.condition}>
                                                <option value="new">New</option>
                                                <option value="used">Used</option>
                                                <option value="refurbished">Refurbished</option>
                                            </select>
                                        </div>

                                        <div class="form-group">
                                            <label for="variant-status-{i}">Status *</label>
                                            <select id="variant-status-{i}" bind:value={variant.status}>
                                                <option value="active">Active</option>
                                                <option value="inactive">Inactive</option>
                                                <option value="draft">Draft</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            {/each}
                        </div>

                        <div class="form-actions">
                            <button type="button" class="cancel-button" on:click={resetForm}>
                                Cancel
                            </button>
                            <button type="submit" class="submit-button">
                                Add Product
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        {/if}
    </div>
{/if}

<style>
    .products-container {
        padding: 2rem;
    }

    .content-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 2rem;
    }

    .add-button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        transition: background 0.2s;
    }

    .add-button:hover {
        background: #3182ce;
    }

    .form-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: flex-start;
        justify-content: center;
        padding: 2rem;
        overflow-y: auto;
        z-index: 1000;
    }

    .form-container {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        width: 100%;
        max-width: 800px;
        margin: auto;
    }

    .form-section {
        margin-bottom: 2rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid #e2e8f0;
    }

    .form-section h3 {
        margin-bottom: 1rem;
        color: #2d3748;
        font-size: 1.25rem;
    }

    .form-group {
        margin-bottom: 1rem;
    }

    .form-group label {
        display: block;
        margin-bottom: 0.5rem;
        color: #4a5568;
        font-weight: 500;
    }

    .form-group input,
    .form-group select,
    .form-group textarea {
        width: 100%;
        padding: 0.75rem;
        border: 2px solid #e2e8f0;
        border-radius: 6px;
        font-size: 1rem;
    }

    .form-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
    }

    .checkbox-group {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
        gap: 0.5rem;
    }

    .checkbox-label {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .variant-container {
        background: #f7fafc;
        padding: 1rem;
        border-radius: 8px;
        margin-bottom: 1rem;
    }

    .variant-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
    }

    .section-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
    }

    .add-variant-button {
        padding: 0.5rem 1rem;
        background: #48bb78;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    .remove-variant-button {
        padding: 0.25rem 0.5rem;
        background: #e53e3e;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.875rem;
    }

    .form-actions {
        display: flex;
        justify-content: flex-end;
        gap: 1rem;
        margin-top: 2rem;
    }

    .cancel-button {
        padding: 0.75rem 1.5rem;
        background: #e2e8f0;
        color: #4a5568;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    .submit-button {
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        border: none;
        border-radius: 6px;
        cursor: pointer;
    }

    .setup-shop {
        text-align: center;
        padding: 2rem;
    }

    .setup-shop h3 {
        font-size: 1.5rem;
        color: #2d3748;
        margin-bottom: 1rem;
    }

    .setup-shop p {
        color: #4a5568;
        margin-bottom: 1.5rem;
    }

    .setup-button {
        display: inline-block;
        padding: 0.75rem 1.5rem;
        background: #4299e1;
        color: white;
        text-decoration: none;
        border-radius: 6px;
        transition: background 0.2s;
    }

    .setup-button:hover {
        background: #3182ce;
    }
</style> 