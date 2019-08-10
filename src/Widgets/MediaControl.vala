public class Widgets.MediaControl : Gtk.Revealer {
    private Granite.SeekBar timeline;
    private Gtk.Label title_label;
    private Gtk.Label subtitle_label;

    private Gtk.Button favorite_button;
    private Gtk.Button lyric_button;
    
    private Gtk.Image icon_favorite;
    private Gtk.Image icon_no_favorite;

    public MediaControl () {

    }
    
    construct {
        icon_favorite = new Gtk.Image.from_icon_name ("byte-favorite-symbolic", Gtk.IconSize.MENU);
        icon_no_favorite = new Gtk.Image.from_icon_name ("byte-no-favorite-symbolic", Gtk.IconSize.MENU);

        timeline = new Granite.SeekBar (0);
        timeline.margin_start = 6;
        timeline.margin_top = 9;
        timeline.margin_end = 6;
        timeline.get_style_context ().remove_class ("seek-bar");
        timeline.get_style_context ().add_class ("byte-seekbar");

        var timeline_revealer = new Gtk.Revealer ();
        timeline_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        timeline_revealer.add (timeline);
        timeline_revealer.reveal_child = false;

        title_label = new Gtk.Label (null);
        title_label.get_style_context ().add_class ("font-bold");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.halign = Gtk.Align.CENTER;
        title_label.selectable = true;

        subtitle_label = new Gtk.Label (null);
        subtitle_label.halign = Gtk.Align.CENTER;
        subtitle_label.ellipsize = Pango.EllipsizeMode.END;
        subtitle_label.selectable = true;

        favorite_button = new Gtk.Button ();
        favorite_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        favorite_button.get_style_context ().add_class ("button-color");
        favorite_button.can_focus = false;
        favorite_button.valign = Gtk.Align.CENTER;
        favorite_button.image = icon_no_favorite;

        var favorite_revealer = new Gtk.Revealer ();
        favorite_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        favorite_revealer.add (favorite_button);
        favorite_revealer.reveal_child = false;

        lyric_button = new Gtk.Button.from_icon_name ("text-x-generic-symbolic", Gtk.IconSize.MENU);
        lyric_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        lyric_button.get_style_context ().add_class ("button-color");
        lyric_button.can_focus = false;
        lyric_button.valign = Gtk.Align.CENTER;

        var lyric_revealer = new Gtk.Revealer ();
        lyric_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        lyric_revealer.add (lyric_button);
        lyric_revealer.reveal_child = false;

        var metainfo_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        metainfo_box.margin_start = 6;
        metainfo_box.margin_end = 6;
        metainfo_box.valign = Gtk.Align.CENTER;
        metainfo_box.add (title_label);
        metainfo_box.add (subtitle_label);

        var image_cover = new Widgets.Cover ();

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.margin = 3;  
        header_box.margin_start = 4;
        header_box.margin_end = 6;      
        header_box.pack_start (image_cover, false, false, 0);
        header_box.set_center_widget (metainfo_box);
        header_box.pack_end (favorite_revealer, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.pack_start (timeline_revealer, false, false, 0);
        main_box.pack_start (header_box, false, false, 0);
        
        add (main_box);

        favorite_button.clicked.connect (() => {
            if (favorite_button.image == icon_favorite) {
                favorite_button.image = icon_no_favorite;
                
                if (Byte.player.current_track != null) {
                    Byte.database.set_track_favorite (Byte.player.current_track, 0);
                }
            } else {
                favorite_button.image = icon_favorite;

                if (Byte.player.current_track != null) {
                    Byte.database.set_track_favorite (Byte.player.current_track, 1);
                }
            }
        });

        Byte.database.updated_track_favorite.connect ((track, favorite) => {
            if (Byte.player.current_track != null && track.id == Byte.player.current_track.id) {
                if (favorite == 0) {
                    favorite_button.image = icon_no_favorite;
                } else {
                    favorite_button.image = icon_favorite;
                }
            }
        });

        Byte.player.current_progress_changed.connect ((progress) => {
            timeline.playback_progress = progress;
            if (timeline.playback_duration == 0) {
                timeline.playback_duration = Byte.player.duration / Gst.SECOND;
            }
        });

        Byte.player.current_duration_changed.connect ((duration) => {
            timeline.playback_duration = duration / Gst.SECOND;
        });

        Byte.player.current_track_changed.connect ((track) => {
            title_label.label = track.title;
            subtitle_label.label = "%s - %s".printf (track.artist_name, track.album_title);

            string cover_path = GLib.Path.build_filename (Byte.utils.COVER_FOLDER, ("track-%i.jpg").printf (track.id));
            image_cover.set_from_file (cover_path, 32, "track");

            if (track.is_favorite == 0) {
                favorite_button.image = icon_no_favorite;
            } else {
                favorite_button.image = icon_favorite;
            }
        });

        Byte.player.current_radio_changed.connect ((radio) => {
            title_label.label = radio.name;
            reveal_child = true;
        });

        Byte.player.current_radio_title_changed.connect ((title) => {
            if (Byte.player.mode == "radio") {
                subtitle_label.label = title;
            }
        });

        Byte.player.state_changed.connect ((state) => {
            if (state == Gst.State.PLAYING) {
                if (Byte.player.current_track != null) {
                    reveal_child = true;
                }
            } else if (state == Gst.State.NULL) {
                reveal_child = false;
            }
        });

        Byte.player.mode_changed.connect ((mode) => {
            if (mode == "radio") {
                timeline_revealer.reveal_child = false;
                favorite_revealer.reveal_child = false;
                lyric_revealer.reveal_child = false;
            } else {
                timeline_revealer.reveal_child = true;
                lyric_revealer.reveal_child = true;

                if (Byte.scan_service.is_sync == false) {
                    favorite_revealer.reveal_child = true;
                }
            }
        });

        Byte.lastfm_service.radio_cover_track_found.connect ((track_url) => {
            print ("URL: %s\n".printf (track_url));
            image_cover.set_from_url_async (track_url, 32, true, "track");
        }); 

        Byte.database.updated_track_cover.connect ((track_id) => {
            Idle.add (() => {
                if (Byte.player.current_track != null && track_id == Byte.player.current_track.id) {
                    try {
                        image_cover.pixbuf = new Gdk.Pixbuf.from_file_at_size (
                            GLib.Path.build_filename (Byte.utils.COVER_FOLDER, ("track-%i.jpg").printf (track_id)), 
                            32, 
                            32);
                    } catch (Error e) {
                        stderr.printf ("Error setting default avatar icon: %s ", e.message);
                    }
                }
                
                return false;
            });
        });
        
        timeline.scale.change_value.connect ((scroll, new_value) => {
            Byte.player.seek_to_progress (new_value);
            return true;
        });

        Byte.scan_service.sync_started.connect (() => {
            favorite_revealer.reveal_child = false;
        });

        Byte.scan_service.sync_finished.connect (() => {
            favorite_revealer.reveal_child = true;
        });
    }
}