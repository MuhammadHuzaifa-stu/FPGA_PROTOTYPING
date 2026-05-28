vga_demo                          hdmi_demo
├── bar_demo          (KEEP)      ├── bar_demo          (KEEP)
├── rgb2gray          (KEEP)      ├── rgb2gray          (KEEP)
├── vga_sync_demo     (KEEP)      ├── vga_sync_demo     (KEEP)
│                                 ├── clk_wiz           (NEW - MMCM)
│                                 ├── tmds_encoder x3   (NEW - R,G,B)
│                                 └── serializer x4     (NEW - +clock)
│
output: hsync, vsync, rgb[11:0]   output: 4 diff pairs to HDMI