node['dotfiles']['vimusers'].each do |username|

  unless node['etc']['passwd'][username]
    username = "travis"
  end

  homepath = lambda {
    path = "/tmp"
    if node['etc']['passwd'][username]
      path = node['etc']['passwd'][username]['dir']
    end
    path
  }

  directory "#{homepath.call}/.vim/autoload" do
    owner username
    mode 00755
    recursive true
    action :create
  end

  remote_file "#{homepath.call}/.vim/autoload/pathogen.vim" do
    source "https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim"
    mode 00755
    owner username
    action :create_if_missing
  end

  node['dotfiles']['vim'].each do |folder, repohash|
    directory "#{homepath.call}/.vim/#{folder}" do
      owner username
      mode 00755
      recursive true
    end
    repohash.each do |repos|
      repos.each do |repo|
        git "#{homepath.call}/.vim/#{folder}/#{repo[0]}" do
          repository repo[1]
          enable_submodules true
          action :sync
          user username
        end
      end
    end
  end

  directory "#{homepath.call}/.vim/colors" do
    owner username
    mode 00755
    recursive true
    action :create
  end

  colorscheme = node['dotfiles']['vimcolorscheme']

  if colorscheme.is_a? Hash
    (colorscheme, src) = colorscheme.first
    remote_file "#{homepath.call}/.vim/colors/#{colorscheme}.vim" do
        source src
        mode 00755
        owner username
        action :create_if_missing
    end
  end

  template "#{homepath.call}/.vimrc" do
    source "vimrc.erb"
    owner username
    variables(
      :colorscheme => colorscheme
    )
  end
end
