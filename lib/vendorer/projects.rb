module Projects
  
  module Rails
  
    def asset(name,opt={},&block)
      base_name = File.basename(name)
      asset_dir = case File.extname(base_name)
        when ".js" then "javascripts"
        when ".coffee" then "coffeescripts"
        when ".css" then "stylesheets"
      end
      path = "app/assets/#{asset_dir}/#{name}"
      unless @options[:update].nil?
        if @options[:update].is_a?(String) and @options[:update].include?(name)
          @options[:update] = path
        end 
      end
      file(path,opt[:source],&block)
    end
    
    def plugin(path, options={},&block)
      raise "Missing source!" unless options.has_key?(:source)
      url = options[:source]
      options.delete(:source)
      folder(path,url,options,&block)
    end
  end
  
end