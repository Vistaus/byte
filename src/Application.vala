public class Byte : Gtk.Application {
    public MainWindow main_window;

    public static Services.Database database;
    public static GLib.Settings settings;
    public static Services.Player player;
    public static Services.TagManager tg_manager;
    public static Services.CoverImport cover_import;
    public static Services.Indicator indicator;
    public static Services.Notification notification;
    public static Services.Scan scan_service;
    public static Services.RadioBrowser radio_browser;
    public static Services.Lastfm lastfm_service;
    public static Utils utils;

    public string[] argsv;
    public bool has_entry_focus = false;
    public SimpleAction toggle_playing_action;

    public static Byte _instance = null;
    public static Byte instance {
        get {
            if (_instance == null) {
                _instance = new Byte ();
            }
            return _instance;
        }
    }

    public Byte () { 
        Object (
            application_id: "com.github.alainm23.byte",
            flags: ApplicationFlags.HANDLES_OPEN
        );
        
        // Dir to Database
        utils = new Utils ();
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.byte");
        utils.create_dir_with_parents ("/.local/share/com.github.alainm23.byte/covers");

        settings = new Settings ("com.github.alainm23.byte");
        player = new Services.Player ();
        database = new Services.Database ();
        tg_manager = new Services.TagManager ();
        cover_import = new Services.CoverImport ();
        notification = new Services.Notification ();
        scan_service = new Services.Scan ();
        radio_browser = new Services.RadioBrowser ();
        lastfm_service = new Services.Lastfm ();
    }

    protected override void activate () {
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        var window_size = settings.get_value ("window-size");
        var rect = Gtk.Allocation ();
        rect.height = (int32) window_size.get_child_value (0);
        rect.width =  (int32) window_size.get_child_value (1);

        var window_position = settings.get_value ("window-position");
        var window_x = (int32) window_position.get_child_value (0);
        var window_y = (int32) window_position.get_child_value (1);

        main_window = new MainWindow (this);
        if (window_x != -1 ||  window_y != -1) {
            main_window.move (window_x, window_y);
        }

        main_window.set_allocation (rect);
        main_window.show_all ();

        // Indicator
        indicator = new Services.Indicator ();
        indicator.initialize ();

        // Media Keys
        Services.MediaKey.listen ();

        // Actions
        var quit_action = new SimpleAction ("quit", null);
        set_accels_for_action ("app.quit", {"<Control>q"});

        toggle_playing_action = new SimpleAction ("toggle_playing_action", null);
        set_accels_for_action ("app.toggle_playing_action", {"space"});

        var search_action = new SimpleAction ("search", null);
        set_accels_for_action ("app.search", {"<Control>f"});

        quit_action.activate.connect (() => {
            if (main_window != null) {
                main_window.destroy ();
            }
        });

        toggle_playing_action.activate.connect (() => {
            if (!has_entry_focus) {
                player.toggle_playing ();
            }
        });

        search_action.activate.connect (() => {
            //player.toggle_playing ();
        });

        add_action (quit_action);
        add_action (toggle_playing_action);
        add_action (search_action);

        // Stylesheet
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/alainm23/byte/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.get_boolean ("dark-mode");

        if (settings.get_boolean ("dark-mode")) {
            var dark_mode_provider = new Gtk.CssProvider ();
            var colored_css = """
                @define-color colorPrimary %s;
                @define-color textColorPrimary %s;
            """.printf ("@base_color", "#fe2851");

            try {
                dark_mode_provider.load_from_data (colored_css, colored_css.length);

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), dark_mode_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                return;
            }
        }

        // Default Icon Theme
        weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
        default_theme.add_resource_path ("/com/github/alainm23/byte");

        if (Byte.settings.get_boolean ("dark-mode")) {
            var provider_theme = new Gtk.CssProvider ();

            var colored_css = """
                @define-color colorPrimary %s;
                @define-color textColorPrimary %s;
            """;
            
            colored_css = colored_css.printf (
                "@base_color",
                "@text_color"
            );

            try {
                provider_theme.load_from_data (colored_css, colored_css.length);

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider_theme, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (GLib.Error e) {
                return;
            }
        } else {
            Byte.utils.apply_theme (Byte.settings.get_enum ("theme"));
        }
    }

    public void toggle_playing_action_enabled (bool b) {
        if (b) {
            set_accels_for_action ("app.toggle_playing_action", {"space"});
        } else {
            set_accels_for_action ("app.toggle_playing_action", {null});
        }
    }

    public static int main (string[] args) {
        Gst.init (ref args);
        var app = Byte.instance;
        return app.run (args);
    }
}
