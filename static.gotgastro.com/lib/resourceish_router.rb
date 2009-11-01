module Nanoc::Routers

  class Resourceish < Nanoc::Router

    identifier :resourceish

    def path_for_page_rep(page_rep)
      # Get data we need
      filename   = page_rep.attribute_named(:filename)
      extension  = page_rep.attribute_named(:extension)

      if page_rep.page.path == '/'
        path = '/' + filename 
      else
        path = page_rep.page.path[0..-2]
      end

      path += '.' + extension

      path
    end

    def path_for_asset_rep(asset_rep)
      # Get data we need
      extension     = asset_rep.attribute_named(:extension)
      modified_path = asset_rep.asset.path[0..-2]
      version       = asset_rep.attribute_named(:version)

      path = modified_path + '.' + extension

      path
    end

  end

end
