require 'test_helper'

module Workarea
  class ProductReleasesTest < TestCase
    def test_product_changes
      product = create_product(name: 'Foo')
      release_one = create_release
      release_one.as_current { product.update!(name: 'Bar') }

      assert_equal([release_one], ProductReleases.new(product).releases)

      release_one.update!(publish_at: 1.day.from_now)
      release_two = create_release(publish_at: 3.days.from_now)
      assert_equal([release_one, release_two], ProductReleases.new(product).releases)
    end

    def test_featured_product_changes
      product = create_product
      category = create_category

      release_one = create_release
      release_one.as_current { category.update!(product_ids: [product.id]) }
      assert_equal([release_one], ProductReleases.new(product).releases)

      release_one.update!(publish_at: 1.day.from_now)
      release_two = create_release(publish_at: 3.days.from_now)
      assert_equal([release_one, release_two], ProductReleases.new(product).releases)
    end

    def test_variant_changes
      product = create_product(variants: [{ sku: 'SKU' }])
      release = create_release
      release.as_current { product.variants.first.update!(details: { color: 'Red' }) }
      assert_equal([release], ProductReleases.new(product).releases)
    end

    def test_pricing_changes
      product = create_product(variants: [{ sku: 'SKU' }])
      pricing = Pricing::Sku.find('SKU')

      release = create_release
      release.as_current { pricing.prices.first.update!(regular: 10_000) }
      assert_equal([release], ProductReleases.new(product).releases)
    end
  end
end
