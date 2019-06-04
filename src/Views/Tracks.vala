public class Views.Tracks : Gtk.EventBox {
    private Gtk.ListBox listbox;
    private Gtk.Revealer loading_revealer;
    public signal void go_back ();

    private bool is_initialized = false;

    public Tracks () {
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class ("w-round");

        var back_button = new Gtk.Button.with_label (_("Back"));
        back_button.margin = 6;
        back_button.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Tracks")));
        title_label.use_markup = true;
        title_label.valign = Gtk.Align.CENTER;
        title_label.get_style_context ().add_class ("h3");

        var search_entry = new Gtk.SearchEntry ();
        search_entry.valign = Gtk.Align.CENTER;
        search_entry.width_request = 250;
        search_entry.get_style_context ().add_class ("search-entry");
        search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        search_entry.placeholder_text = _("Your library");

        var center_stack = new Gtk.Stack ();
        center_stack.hexpand = true;
        center_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        center_stack.add_named (title_label, "title_label");
        center_stack.add_named (search_entry, "search_entry");
        
        center_stack.visible_child_name = "title_label";

        var search_button = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.MENU);
        search_button.margin = 6;
        search_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.pack_start (back_button, false, false, 0);
        header_box.set_center_widget (center_stack);
        header_box.pack_end (search_button, false, false, 0);

        listbox = new Gtk.ListBox ();
        listbox.expand = true;

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.expand = true;
        scrolled.add (listbox);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (header_box, false, false, 0);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        main_box.pack_start (scrolled, true, true, 0);
        
        add (main_box);

        back_button.clicked.connect (() => {
            go_back ();
        });

        Byte.database.adden_new_track.connect ((track) => {
            Idle.add (() => {
                add_track (track);

                return false;
            });
        });
    }

    private void add_track (Objects.Track track) {
        var row = new Widgets.TrackRow (track);
        listbox.add (row);
        
        listbox.show_all ();
    }

    public void get_all_tracks () {
        if (is_initialized == false) {
            Timeout.add (120, () => {
                    new Thread<void*> ("get_all_tracks", () => {
                        var all_tracks = new Gee.ArrayList<Objects.Track?> ();
                        all_tracks = Byte.database.get_all_tracks ();
        
                        foreach (var item in all_tracks) {
                            Idle.add (() => {
                                add_track (item);
        
                                return false;
                            });
                        
                        }
                        
                        print ("Termino\n");
                        is_initialized = true;
                        return null;
                    });

                return false;
            });
        }
    }
}