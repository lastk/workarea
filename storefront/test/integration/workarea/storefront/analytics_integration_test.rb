require 'test_helper'

module Workarea
  module Storefront
    class AnalyticsIntegrationTest < Workarea::IntegrationTest
      def test_saving_product_view
        post storefront.analytics_product_view_path(product_id: ' ')
        assert_equal(0, Metrics::ProductByDay.count)

        post storefront.analytics_product_view_path(product_id: 'foo')

        assert_equal(1, Metrics::ProductByDay.first.views)
        user = Metrics::User.first
        assert_equal(session.id, user.id)
        assert_equal(['foo'], user.viewed.product_ids)
      end

      def test_saving_search
        post storefront.analytics_search_path(q: ' ', total_results: '5')
        assert_equal(0, Metrics::SearchByDay.count)

        post storefront.analytics_search_path(q: 'foods', total_results: '5')

        metrics = Metrics::SearchByDay.first
        assert_equal(1, metrics.searches)
        assert_equal(5, metrics.total_results)

        user = Metrics::User.first
        assert_equal(session.id, user.id)
        assert_equal(['food'], user.viewed.search_ids)
      end

      def test_saving_category_view
        post storefront.analytics_category_view_path(category_id: ' ')
        assert_equal(0, Metrics::CategoryByDay.count)

        post storefront.analytics_category_view_path(category_id: 'foo')

        assert_equal(1, Metrics::CategoryByDay.first.views)
        user = Metrics::User.first
        assert_equal(session.id, user.id)
        assert_equal(['foo'], user.viewed.category_ids)
      end

      def test_blocking_bots
        post storefront.analytics_product_view_path(product_id: 'foo'),
          headers: { 'HTTP_USER_AGENT' => 'Googlebot' }

        assert(Metrics::ProductByDay.count.zero?)
        assert(Metrics::User.count.zero?)
      end

      def test_merging_metrics_on_login
        create_user(email: 'bcrouse@workarea.com', password: 'W3bl1nc!')
        login_metrics = Metrics::User.create!(
          id: 'bcrouse@workarea.com',
          orders: 1,
          viewed: { product_ids: ['bar'] }
        )

        post storefront.analytics_product_view_path(product_id: 'foo')
        session_metrics = Metrics::User.find(session.id)
        assert_equal(['foo'], session_metrics.viewed.product_ids)

        post storefront.login_path,
          params: { email: 'bcrouse@workarea.com', password: 'W3bl1nc!' }

        login_metrics.reload
        assert_equal(1, login_metrics.orders)
        assert_equal(%w(bar foo), login_metrics.viewed.product_ids)
      end
    end
  end
end
