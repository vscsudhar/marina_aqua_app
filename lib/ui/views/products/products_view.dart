import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:marina_aqua/models/category_model.dart';
import 'package:marina_aqua/models/product_model.dart';
import 'package:marina_aqua/models/unit_model.dart';
import 'package:marina_aqua/ui/common/app_colors.dart';
import 'products_viewmodel.dart';
import 'widgets/category_form_dialog.dart';
import 'widgets/product_form_dialog.dart';
import 'widgets/unit_form_dialog.dart';

class ProductsView extends StackedView<ProductsViewModel> {
  final VoidCallback? onBack;

  const ProductsView({super.key, this.onBack});

  @override
  ProductsViewModel viewModelBuilder(BuildContext context) =>
      ProductsViewModel();

  @override
  void onViewModelReady(ProductsViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
  }

  @override
  Widget builder(
    BuildContext context,
    ProductsViewModel viewModel,
    Widget? child,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      appBar: _buildAppBar(context, viewModel),
      body: Column(
        children: [
          _buildMetricsStrip(viewModel, isDesktop, isTablet),
          _buildTabBar(viewModel),
          Expanded(
            child: IndexedStack(
              index: viewModel.selectedTabIndex,
              children: [
                _buildProductsTab(context, viewModel, isDesktop),
                _buildCategoriesTab(context, viewModel, isDesktop),
                _buildUnitsTab(context, viewModel, isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ProductsViewModel viewModel) {
    return AppBar(
      backgroundColor: kcDeepNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? viewModel.navigateBack,
        tooltip: 'Back to Dashboard',
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kcPrimaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: kcPrimaryLight, size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Master & Catalog',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Water Products, Raw Materials, Units & Inventory Rules',
                style: TextStyle(fontSize: 11, color: kcLightGrey),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
          onPressed: () {
            if (viewModel.selectedTabIndex == 0) {
              viewModel.fetchProducts();
            } else if (viewModel.selectedTabIndex == 1) {
              viewModel.fetchCategories();
            } else {
              viewModel.fetchUnits();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMetricsStrip(
      ProductsViewModel viewModel, bool isDesktop, bool isTablet) {
    if (!isDesktop && !isTablet) {
      return Container(
        color: kcSurfaceWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: _buildMetricTile(
                  label: 'Total Products',
                  value: viewModel.totalProductsCount.toString(),
                  icon: Icons.inventory_2,
                  color: kcPrimaryColor,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 200,
                child: _buildMetricTile(
                  label: 'Active Catalog',
                  value: viewModel.activeProductsCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: kcSuccessColor,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 200,
                child: _buildMetricTile(
                  label: 'Low Stock Alert',
                  value: viewModel.lowStockProductsCount.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: viewModel.lowStockProductsCount > 0
                      ? kcErrorColor
                      : kcMediumGrey,
                  isAlert: viewModel.lowStockProductsCount > 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: kcSurfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricTile(
              label: 'Total Products',
              value: viewModel.totalProductsCount.toString(),
              icon: Icons.inventory_2,
              color: kcPrimaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: 'Active Catalog',
              value: viewModel.activeProductsCount.toString(),
              icon: Icons.check_circle_outline,
              color: kcSuccessColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: 'Refill Products',
              value: viewModel.refillProductsCount.toString(),
              icon: Icons.autorenew_rounded,
              color: kcPrimaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              label: 'Low Stock Alert',
              value: viewModel.lowStockProductsCount.toString(),
              icon: Icons.warning_amber_rounded,
              color: viewModel.lowStockProductsCount > 0
                  ? kcErrorColor
                  : kcMediumGrey,
              isAlert: viewModel.lowStockProductsCount > 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAlert ? color.withValues(alpha: 0.08) : kcVeryLightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAlert ? color.withValues(alpha: 0.3) : kcBorderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: kcTextSecondary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isAlert ? color : kcTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ProductsViewModel viewModel) {
    return Container(
      decoration: const BoxDecoration(
        color: kcSurfaceWhite,
        border: Border(bottom: BorderSide(color: kcBorderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem(
              index: 0,
              title: 'Products Master',
              icon: Icons.local_drink_rounded,
              badgeCount: viewModel.totalProductsCount,
              isSelected: viewModel.selectedTabIndex == 0,
              onTap: () => viewModel.setTab(0),
            ),
            _buildTabItem(
              index: 1,
              title: 'Categories',
              icon: Icons.category_rounded,
              badgeCount: viewModel.categories.length,
              isSelected: viewModel.selectedTabIndex == 1,
              onTap: () => viewModel.setTab(1),
            ),
            _buildTabItem(
              index: 2,
              title: 'Units of Measurement',
              icon: Icons.straighten_rounded,
              badgeCount: viewModel.units.length,
              isSelected: viewModel.selectedTabIndex == 2,
              onTap: () => viewModel.setTab(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String title,
    required IconData icon,
    required int badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? kcPrimaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? kcPrimaryColor : kcMediumGrey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? kcPrimaryColor : kcTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? kcPrimaryColor.withValues(alpha: 0.12)
                    : kcVeryLightGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? kcPrimaryColor : kcMediumGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // TAB 1: PRODUCTS
  // ========================================================

  Widget _buildProductsTab(
      BuildContext context, ProductsViewModel viewModel, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Toolbar
          _buildProductFilterToolbar(context, viewModel),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: viewModel.isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : viewModel.productsError != null
                    ? _buildErrorView(
                        viewModel.productsError!,
                        onRetry: () => viewModel.fetchProducts(),
                      )
                    : viewModel.products.isEmpty
                        ? _buildEmptyView(
                            title: 'No Products Found',
                            description:
                                'No products match your search or filter criteria. Create your first product to get started.',
                            actionLabel: 'Add Product',
                            onAction: () =>
                                _openProductFormDialog(context, viewModel),
                          )
                        : _buildProductsListOrTable(
                            context, viewModel, isDesktop),
          ),
          // Pagination Bar
          if (viewModel.products.isNotEmpty) _buildPaginationBar(viewModel),
        ],
      ),
    );
  }

  Widget _buildProductFilterToolbar(
      BuildContext context, ProductsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Search Box
          SizedBox(
            width: 260,
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search product, SKU, HSN...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: viewModel.productSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => viewModel.setProductSearch(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kcBorderColor),
                ),
              ),
              onChanged: viewModel.setProductSearch,
            ),
          ),
          // Category Filter
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<int?>(
              initialValue: viewModel.selectedCategoryFilter,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: const Text('All Categories',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All Categories',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                ...viewModel.categories.map((c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.name,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: viewModel.setCategoryFilter,
            ),
          ),
          // Product Type Filter (Normal / Refill)
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String?>(
              initialValue: viewModel.selectedProductTypeFilter,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: const Text('Type: All',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Type: All',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem<String?>(
                  value: 'normal',
                  child: Text('Normal Only',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem<String?>(
                  value: 'refill',
                  child: Text('Refill Only',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: viewModel.setProductTypeFilter,
            ),
          ),
          // Status Filter
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<bool?>(
              initialValue: viewModel.selectedStatusFilter,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              hint: const Text('Status: All',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              items: const [
                DropdownMenuItem<bool?>(
                  value: null,
                  child: Text('Status: All',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem<bool?>(
                  value: true,
                  child: Text('Active Only',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem<bool?>(
                  value: false,
                  child: Text('Inactive Only',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: viewModel.setStatusFilter,
            ),
          ),
          // Low Stock Toggle Chip
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: viewModel.lowStockOnly ? Colors.white : kcErrorColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Low Stock',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: viewModel.lowStockOnly ? Colors.white : kcErrorColor,
                  ),
                ),
              ],
            ),
            selected: viewModel.lowStockOnly,
            selectedColor: kcErrorColor,
            backgroundColor: kcErrorColor.withValues(alpha: 0.08),
            side: BorderSide(color: kcErrorColor.withValues(alpha: 0.4)),
            onSelected: (_) => viewModel.toggleLowStockFilter(),
          ),
          // Add Product Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Product',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => _openProductFormDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsListOrTable(
      BuildContext context, ProductsViewModel viewModel, bool isDesktop) {
    if (!isDesktop) {
      // Mobile / Compact Card View
      return ListView.separated(
        itemCount: viewModel.products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, index) {
          final product = viewModel.products[index];
          return _buildProductCard(context, viewModel, product);
        },
      );
    }

    // Desktop Table View
    return Container(
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(kcVeryLightGrey),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: const [
              DataColumn(
                  label: Text('Product & SKU',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Category',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Unit',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Sale Price (₹)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Cost Price (₹)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Stock / Reorder',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Status',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(
                  label: Text('Actions',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: viewModel.products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: kcTextPrimary),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kcVeryLightGrey,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: kcBorderColor),
                              ),
                              child: Text(
                                product.sku,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: kcTextSecondary),
                              ),
                            ),
                            if (product.isRefill) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kcPrimaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: kcPrimaryColor.withValues(
                                          alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.autorenew_rounded,
                                        size: 10, color: kcPrimaryDark),
                                    SizedBox(width: 3),
                                    Text(
                                      'REFILL',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: kcPrimaryDark),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (product.hsnCode.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                'HSN: ${product.hsnCode}',
                                style: const TextStyle(
                                    fontSize: 10, color: kcMediumGrey),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Chip(
                      label: Text(product.categoryName,
                          style: const TextStyle(fontSize: 11)),
                      backgroundColor: kcPrimaryColor.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  DataCell(
                    Text(
                      '${product.unitName} (${product.unitCode.isNotEmpty ? product.unitCode : product.unitName})',
                      style:
                          const TextStyle(fontSize: 12, color: kcTextSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹${product.defaultPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: kcPrimaryDark),
                    ),
                  ),
                  DataCell(
                    product.isRefill
                        ? const Text(
                            '— (Refill)',
                            style: TextStyle(
                                fontSize: 12,
                                color: kcMediumGrey,
                                fontStyle: FontStyle.italic),
                          )
                        : Text(
                            '₹${product.costPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12, color: kcTextSecondary),
                          ),
                  ),
                  DataCell(
                    product.isRefill
                        ? const Text(
                            'N/A (Refill)',
                            style: TextStyle(
                                fontSize: 12,
                                color: kcMediumGrey,
                                fontStyle: FontStyle.italic),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.currentStock.toStringAsFixed(0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: product.isLowStock
                                      ? kcErrorColor
                                      : kcTextPrimary,
                                ),
                              ),
                              Text(
                                ' / min ${product.minStockLevel.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 11, color: kcMediumGrey),
                              ),
                              if (product.isLowStock) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kcErrorColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'LOW',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: kcErrorColor),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  DataCell(
                    Switch(
                      value: product.isActive,
                      activeThumbColor: kcSuccessColor,
                      onChanged: (_) => viewModel.toggleProductStatus(product),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: kcPrimaryColor),
                          tooltip: 'Edit Product',
                          onPressed: () => _openProductFormDialog(
                              context, viewModel,
                              product: product),
                        ),
                        IconButton(
                          icon: Icon(
                            product.isReferenced
                                ? Icons.archive_outlined
                                : Icons.delete_outline,
                            size: 18,
                            color: product.isReferenced
                                ? kcWarningColor
                                : kcErrorColor,
                          ),
                          tooltip: product.isReferenced
                              ? 'Deactivate (Referenced)'
                              : 'Delete Product',
                          onPressed: () =>
                              viewModel.confirmDeleteProduct(context, product),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, ProductsViewModel viewModel, ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (product.isNormal && product.isLowStock)
              ? kcErrorColor.withValues(alpha: 0.3)
              : kcBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kcTextPrimary),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.isRefill) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kcPrimaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: kcPrimaryColor.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew_rounded,
                              size: 11, color: kcPrimaryDark),
                          SizedBox(width: 4),
                          Text(
                            'Refill',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: kcPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? kcSuccessColor.withValues(alpha: 0.12)
                          : kcMediumGrey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: product.isActive ? kcSuccessColor : kcMediumGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kcVeryLightGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.sku,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: kcTextSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${product.categoryName} • ${product.unitName}',
                style: const TextStyle(fontSize: 12, color: kcMediumGrey),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selling Price',
                      style: TextStyle(fontSize: 10, color: kcMediumGrey)),
                  Text(
                    '₹${product.defaultPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: kcPrimaryDark),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cost Price',
                      style: TextStyle(fontSize: 10, color: kcMediumGrey)),
                  Text(
                    product.isRefill
                        ? '— (Refill)'
                        : '₹${product.costPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            product.isRefill ? kcMediumGrey : kcTextSecondary,
                        fontStyle: product.isRefill
                            ? FontStyle.italic
                            : FontStyle.normal),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Physical Stock',
                      style: TextStyle(fontSize: 10, color: kcMediumGrey)),
                  product.isRefill
                      ? const Text(
                          'N/A (Refill)',
                          style: TextStyle(
                              fontSize: 13,
                              color: kcMediumGrey,
                              fontStyle: FontStyle.italic),
                        )
                      : Row(
                          children: [
                            Text(
                              product.currentStock.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: product.isLowStock
                                    ? kcErrorColor
                                    : kcTextPrimary,
                              ),
                            ),
                            if (product.isLowStock) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.warning,
                                  size: 14, color: kcErrorColor),
                            ],
                          ],
                        ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                onPressed: () => _openProductFormDialog(context, viewModel,
                    product: product),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(
                  product.isReferenced
                      ? Icons.archive_outlined
                      : Icons.delete_outline,
                  size: 16,
                  color: product.isReferenced ? kcWarningColor : kcErrorColor,
                ),
                label: Text(
                  product.isReferenced ? 'Deactivate' : 'Delete',
                  style: TextStyle(
                      color:
                          product.isReferenced ? kcWarningColor : kcErrorColor),
                ),
                onPressed: () =>
                    viewModel.confirmDeleteProduct(context, product),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(ProductsViewModel viewModel) {
    final meta = viewModel.productMeta;
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing page ${meta.currentPage} of ${meta.lastPage} (${meta.total} total products)',
            style: const TextStyle(fontSize: 12, color: kcMediumGrey),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcSurfaceWhite,
                  foregroundColor: kcTextPrimary,
                  elevation: 0,
                  side: const BorderSide(color: kcBorderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Previous'),
                onPressed: meta.currentPage > 1
                    ? () => viewModel.fetchProducts(page: meta.currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kcSurfaceWhite,
                  foregroundColor: kcTextPrimary,
                  elevation: 0,
                  side: const BorderSide(color: kcBorderColor),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Next'),
                onPressed: meta.hasMore
                    ? () => viewModel.fetchProducts(page: meta.currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 2: CATEGORIES
  // ========================================================

  Widget _buildCategoriesTab(
      BuildContext context, ProductsViewModel viewModel, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Category Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kcSurfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kcBorderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: viewModel.setCategorySearch,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Category',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openCategoryFormDialog(context, viewModel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Categories Grid / List
          Expanded(
            child: viewModel.isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : viewModel.categoriesError != null
                    ? _buildErrorView(viewModel.categoriesError!,
                        onRetry: viewModel.fetchCategories)
                    : viewModel.categories.isEmpty
                        ? _buildEmptyView(
                            title: 'No Categories Found',
                            description:
                                'Categories help group water cans, bottled boxes, and raw packaging materials.',
                            actionLabel: 'Add Category',
                            onAction: () =>
                                _openCategoryFormDialog(context, viewModel),
                          )
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 3 : 1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 150,
                            ),
                            itemCount: viewModel.categories.length,
                            itemBuilder: (ctx, index) {
                              final cat = viewModel.categories[index];
                              return _buildCategoryCard(
                                  context, viewModel, cat);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, ProductsViewModel viewModel, CategoryModel cat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kcPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.category,
                        size: 16, color: kcPrimaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kcTextPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cat.isActive
                      ? kcSuccessColor.withValues(alpha: 0.12)
                      : kcMediumGrey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cat.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cat.isActive ? kcSuccessColor : kcMediumGrey,
                  ),
                ),
              ),
            ],
          ),
          Text(
            cat.description ?? 'Code: ${cat.code}',
            style: const TextStyle(fontSize: 12, color: kcTextSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text('${cat.productsCount} products',
                    style: const TextStyle(fontSize: 10)),
                backgroundColor: kcVeryLightGrey,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: kcPrimaryColor),
                    tooltip: 'Edit Category',
                    onPressed: () => _openCategoryFormDialog(context, viewModel,
                        category: cat),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: kcErrorColor),
                    tooltip: 'Delete Category',
                    onPressed: () =>
                        viewModel.confirmDeleteCategory(context, cat),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TAB 3: UNITS
  // ========================================================

  Widget _buildUnitsTab(
      BuildContext context, ProductsViewModel viewModel, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Unit Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kcSurfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kcBorderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search units (Litre, ML, NOS, KG)...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: viewModel.setUnitSearch,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kcPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Measurement Unit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _openUnitFormDialog(context, viewModel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Units Grid / List
          Expanded(
            child: viewModel.isLoadingUnits
                ? const Center(child: CircularProgressIndicator())
                : viewModel.unitsError != null
                    ? _buildErrorView(viewModel.unitsError!,
                        onRetry: viewModel.fetchUnits)
                    : viewModel.units.isEmpty
                        ? _buildEmptyView(
                            title: 'No Units Found',
                            description:
                                'Define units such as Litre, ml, nos, kg and pack for accurate stock accounting.',
                            actionLabel: 'Add Measurement Unit',
                            onAction: () =>
                                _openUnitFormDialog(context, viewModel),
                          )
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 3 : 1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 150,
                            ),
                            itemCount: viewModel.units.length,
                            itemBuilder: (ctx, index) {
                              final unit = viewModel.units[index];
                              return _buildUnitCard(context, viewModel, unit);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(
      BuildContext context, ProductsViewModel viewModel, UnitModel unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kcBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kcAquaCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.straighten,
                        size: 16, color: kcAquaTeal),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kcTextPrimary),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kcVeryLightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      unit.code,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kcTextSecondary),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: unit.isActive
                      ? kcSuccessColor.withValues(alpha: 0.12)
                      : kcMediumGrey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  unit.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: unit.isActive ? kcSuccessColor : kcMediumGrey,
                  ),
                ),
              ),
            ],
          ),
          Text(
            unit.description ?? 'Standard unit: ${unit.name} (${unit.code})',
            style: const TextStyle(fontSize: 12, color: kcTextSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text('${unit.productsCount} products',
                    style: const TextStyle(fontSize: 10)),
                backgroundColor: kcVeryLightGrey,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: kcPrimaryColor),
                    tooltip: 'Edit Unit',
                    onPressed: () =>
                        _openUnitFormDialog(context, viewModel, unit: unit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: kcErrorColor),
                    tooltip: 'Delete Unit',
                    onPressed: () => viewModel.confirmDeleteUnit(context, unit),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // SHARED STATES & DIALOG OPENERS
  // ========================================================

  Widget _buildEmptyView({
    required String title,
    required String description,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kcPrimaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined,
                size: 48, color: kcPrimaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kcTextPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kcTextSecondary),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: kcPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel),
            onPressed: onAction,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: kcErrorColor),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: kcErrorColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }

  void _openProductFormDialog(BuildContext context, ProductsViewModel viewModel,
      {ProductModel? product}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProductFormDialog(
        product: product,
        categories: viewModel.categories,
        units: viewModel.units,
        onAddUnit: () async {
          final result = await showDialog<dynamic>(
            context: context,
            barrierDismissible: false,
            builder: (unitCtx) => UnitFormDialog(
              onSave: (
                  {required name,
                  required code,
                  description,
                  required isActive}) {
                return viewModel.saveUnit(
                  name: name,
                  code: code,
                  description: description,
                  isActive: isActive,
                );
              },
            ),
          );
          if (result is UnitModel) {
            return result;
          }
          return null;
        },
        onSave: (data) => viewModel.saveProduct(data, productId: product?.id),
      ),
    );
  }

  void _openCategoryFormDialog(
      BuildContext context, ProductsViewModel viewModel,
      {CategoryModel? category}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CategoryFormDialog(
        category: category,
        onSave: (
            {required name, required code, description, required isActive}) {
          return viewModel.saveCategory(
            id: category?.id,
            name: name,
            code: code,
            description: description,
            isActive: isActive,
          );
        },
      ),
    );
  }

  void _openUnitFormDialog(BuildContext context, ProductsViewModel viewModel,
      {UnitModel? unit}) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UnitFormDialog(
        unit: unit,
        onSave: (
            {required name, required code, description, required isActive}) {
          return viewModel.saveUnit(
            id: unit?.id,
            name: name,
            code: code,
            description: description,
            isActive: isActive,
          );
        },
      ),
    );
  }
}
