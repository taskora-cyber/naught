{
  pkgs,
  version,
  sshkeys,
  hostname,
  username,
  userpswd,
  rootpswd,
  binTohash,
  ...
}: {
  # 设置用户规则
  users = {
    # 是否允许修改用户配置
    mutableUsers = false;
    # 默认用户主目录的根路径
    defaultUserHome = "/home";
    # 默认登录shell设置为zsh
    defaultUserShell = pkgs.zsh;
    # 允许无密码登录
    allowNoPasswordLogin = false;
    # 具体用户配置
    users = {
      ${username} = {
        # 用户 ID
        uid = 1000;
        # 自动创建家目录
        createHome = true;
        # 用户包列表.
        # 它将被添加进系统包列表中.
        # 所以写在`systemPackages`效果一样.
        packages = with pkgs; [
          loupe
          podman-compose
        ];
        # 附加用户组
        extraGroups = [
          "input"
          "wheel"
          "networkmanager"
        ];
        # 标记为普通用户
        isNormalUser = true;
        # 设置此用户的哈希密码
        hashedPassword = binTohash userpswd;
        # 用户SSH配置
        openssh.authorizedKeys.keys = sshkeys;
      };
      # 特级权限用户的哈希密码
      root.hashedPassword = binTohash rootpswd;
    };
  };

  # 状态版本
  system.stateVersion = version;
  # 网络配置
  networking.hostName = hostname; # 设置主机名
  networking.networkmanager.enable = true; # 启用networkmanager,支持无线网络管理

  # 时区设置
  time.timeZone = "Asia/Shanghai"; # 设置时区为上海 中国标准时间
  time.hardwareClockInLocalTime = true; # 同步硬件时钟至本地时间

  # 本地化配置
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LANGUAGE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # 键盘布局
  console.keyMap = "us";

  # 服务配置与桌面环境配置
  services = {
    # X11服务器配置
    xserver = {
      enable = true; # 启用X11窗口系统
      xkb.layout = "us"; # X服务键盘布局
      excludePackages = [pkgs.xterm]; # 设置无须安装的X11系统包
    };
    pulseaudio.enable = false; # 禁用PulseAudio, 使用Pipewire替代
    # GNOME 密钥环（SSH + 机密存储）
    gnome.gnome-keyring.enable = true;
    # 配置文件同步守护进程：将配置文件保存在tmpfs,可延长磁盘寿命.
    # 磁盘内存足够充裕时才值得开启,否则意义不大.
    psd.enable = true;
    psd.resyncTimer = "10m";
    # 现代化的输入库协议栈，支持触控板、鼠标、键盘
    libinput.enable = true;
    # 系统与用户的"消息总线".
    # 让程序之间能够随时互相喊话传数据发事件.
    # 但不用彼此的硬编码、硬依赖
    dbus = {
      enable = true;
      implementation = "broker"; # 更快、更安全的`dbus-daemon`替代
      packages = with pkgs; [gcr gnome-settings-daemon]; # 额外策略文件
    };
    # 虚拟文件系统层(支持 sftp、smb、回收站等）
    gvfs.enable = true;
    # "电池/UPS"监控
    upower.enable = true;
    # Flatpak 沙箱支持
    flatpak.enable = true;
    # 可移动媒体挂载与分区管理
    udisks2.enable = true;
    #提供“平衡/性能/省电”模式切换
    power-profiles-daemon.enable = true;
    # 打印机服务 可选
    avahi = {
      enable = false;
      nssmdns4 = false;
      openFirewall = true;
    };
    ipp-usb.enable = false;
    printing.enable = false;
    printing.drivers = [pkgs.hplipWithPlugin];
    # 远程连接 openssh服务
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };
    };
  };
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;

  # 音频配置
  security.rtkit.enable = true; # 启用RTkit实时内核支持 用于音频权限
  services.pipewire = {
    enable = true; # 启用Pipewire多媒体框架
    alsa = {
      enable = true; # 启用Pipewire的ALSA兼容层
      support32Bit = true; # 支持32位的ALSA应用
    };
    jack.enable = true; # 启用JACK兼容层
    pulse.enable = true; # 启用PulseAudio兼容层
    wireplumber.enable = true; # 启用WirePlumber
  };

  # 蓝牙配置
  hardware.bluetooth.enable = true; # 启用内核蓝牙模块与sytemd服务
  hardware.bluetooth.powerOnBoot = true; # 在启动过程中自动启用蓝牙适配器

  # 安全设置
  security = {
    # 启用doas并设置其附加规则
    doas = {
      enable = true;
      extraRules = [
        {
          users = [username];
          noPass = true;
          keepEnv = true;
        }
      ];
    };
    # 启用sudo并设置其附加规则
    sudo = {
      enable = true;
      extraRules = [
        {
          users = [username];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };
    # 开启`polkit`安全服务
    polkit.enable = true;
  };

  # 系统环境设置
  environment = {
    # 系统包,所有普通用户都可看到
    # 不建议下载太多的系统包
    systemPackages = with pkgs; [
      git
      gcc
      wget
      curl
      blueman
      gnumake
      cmake
      ntfs3g
      base16-schemes
      home-manager
      polkit
      polkit_gnome
    ];
    # 全局环境变量
    variables = {
      EDITOR = "lvim";
    };
    # 仅在此会话中生效的环境变量
    sessionVariables = {
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "ibus";
      QT_SCALE_FACTOR_ROUNDING_POLICY = "round";
      GSK_RENDERER = "vulkan";
      NIXOS_OZONE_WL = "1";
    };
    # 将本地化/国际化的工具提前
    # 塞进用户的$PATH中
    localBinInPath = true;
  };

  # 方便查看包用法或说明
  documentation.man.generateCaches = true;

  # 自启动polkit
  systemd.user.services = {
    polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
    niri-flake-polkit.enable = false;
  };
}
