# _plugins/tags.rb

module Jekyll

  class MyTagIndex < Page
    def initialize(site, base, dir, tags)    
      @site = site
      @base = base
      @dir = dir
      @name = 'tags.html'
      self.process(@name)
      tag_index = (site.config['tag_index_layout'] || 'tag_index') + '.html'
      self.read_yaml(File.join(base, '_layouts'), tag_index)
      self.data['pages_by_tags'] = tags
      self.data['title'] = "Tag index"
    end
  end  
  
  class TagGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'tag_index'
        dir = "."
        tags = Hash[site.pages_by_tag.sort]
        generate_tag_index(site, dir, tags)           
      end
    end

    def generate_tag_index(site, dir, tags)
      index = MyTagIndex.new(site, site.source, dir, tags)
      index.render(site.layouts, site.site_payload)
      index.write(site.dest)
      site.pages << index
    end
  end

end