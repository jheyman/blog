module Jekyll
  class Site

    def pages_by_tag
      tag_ref = {}
      temp = self.posts.dup
      temp.concat(self.pages)
      temp.each do |page|  
        page.tags.each do |tag|
          pages = tag_ref.fetch(tag, Array.new)
          pages << page
          tag_ref[tag] = pages
        end
      end
      tag_ref
    end
  end
end