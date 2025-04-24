# How to Change Product Images in the Retail Store Sample App

This guide explains how product images are used in the retail store sample application and provides instructions for changing them.

## How Product Images Work

### Image Location and Naming

Product images are stored in:
```
./src/ui/src/main/resources/static/assets/img/products/
```

Each image follows these conventions:
- Format: PNG files
- Naming: UUID format (e.g., `1ca35e86-4b4c-4124-b6b5-076ba4134d0d.png`)
- These UUIDs correspond to product IDs in the application database

### How Images are Referenced

The application uses Thymeleaf templates to dynamically reference product images:

1. In catalog listings (`product_card.html`):
   ```html
   th:src="@{/assets/img/products/{itemId}.png(itemId=${item.id})}"
   ```

2. In product detail pages (`detail.html`):
   ```html
   th:src="@{/assets/img/products/{itemId}.png(itemId=${item.id})}"
   ```

### Deployment Process

1. Images are stored as static resources in the Spring Boot application
2. They're packaged into the application JAR/WAR during the build process
3. Spring Boot's embedded web server serves these files directly when requested
4. No special controller is needed - Spring handles static resources automatically

## Steps to Change Product Images

1. **Identify Current Images**
   ```bash
   ls -la ./src/ui/src/main/resources/static/assets/img/products/
   ```

2. **Prepare New Images**
   - Create new product images in PNG format
   - Maintain similar dimensions to existing images for consistent UI appearance
   - Consider using image editing software to optimize for web display

3. **Replace Images**
   - Option 1: Keep the same filenames (UUIDs) to match existing product IDs
     ```bash
     # Example: Replace a specific product image
     cp your-new-image.png ./src/ui/src/main/resources/static/assets/img/products/1ca35e86-4b4c-4124-b6b5-076ba4134d0d.png
     ```
   
   - Option 2: Use new filenames, but update the product database to match new IDs
     (This requires additional database changes not covered in this guide)

4. **Test Changes**
   - Run the application locally to verify your images appear correctly
   - Check both the catalog page and individual product detail pages

5. **Rebuild and Deploy**
   - Rebuild the application to include your new images
   - Deploy according to your preferred deployment method (Docker, Kubernetes, etc.)

## Important Notes

- The image filenames must exactly match the product IDs in the database
- All product images should be in PNG format
- Keep image file sizes reasonable for optimal page loading performance
- The application expects all product images to exist - missing images will result in broken image links

## Example Product IDs

Here are the current product IDs used in the application:

```
1ca35e86-4b4c-4124-b6b5-076ba4134d0d.png
4f18544b-70a5-4352-8e19-0d070f46745d.png
631a3db5-ac07-492c-a994-8cd56923c112.png
79bce3f3-935f-4912-8c62-0d2f3e059405.png
8757729a-c518-4356-8694-9e795a9b3237.png
87e89b11-d319-446d-b9be-50adcca5224a.png
a1258cd2-176c-4507-ade6-746dab5ad625.png
cc789f85-1476-452a-8100-9e74502198e0.png
d27cf49f-b689-4a75-a249-d373e0330bb5.png
d3104128-1d14-4465-99d3-8ab9267c687b.png
d4edfedb-dbe9-4dd9-aae8-009489394955.png
d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49.png
```
