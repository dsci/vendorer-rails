module FileHelper
  def write(file, content)
    File.open("spec/tmp/#{file}",'w'){|f| f.write(content) }
  end

  def read(file)
    File.read("spec/tmp/#{file}")
  end

  def size(file)
    File.size("spec/tmp/#{file}")
  end

  def ls(path)
    `ls spec/tmp/#{path} 2>&1`.split("\n")
  end

  def run(args='', options={})
    out = `cd spec/tmp && bundle exec ../../bin/vendorer #{args} 2>&1`
    p out
    raise out if $?.success? == !!options[:raise]
    out
  end
end