pub use handlebars::Handlebars;
use std::path::Path;

// We call register_templates on startup for each web worker.
// If that encounters problems then we do not know which templates, if any, that we can reliably render.
// We treat that an unrecoverable error, so this function may panic.
pub fn register_templates<'a>() -> Handlebars<'a> {
    let mut template_registry = Handlebars::new();
    template_registry.set_strict_mode(true);

    let partials_path = Path::new("./src/templates/partials/");
    let templates_path = Path::new("./src/templates/");

    for entry in partials_path.read_dir().expect(&format!("read_dir call failed for {:?}", partials_path)) {
        register_template_dir_entry(& mut template_registry, entry);
    }

    for entry in templates_path.read_dir().expect(&format!("read_dir call failed for {:?}", templates_path)) {
        register_template_dir_entry(& mut template_registry, entry);
    }

    template_registry
}

fn register_template_dir_entry(template_registry: &mut Handlebars, entry: Result<std::fs::DirEntry, std::io::Error>) {
    if let Ok(entry) = entry {
        let path = entry.path();
        let ext = path.extension();
        if let Some(ext) = ext {
            if ext == "hbs" {
                let name = path.file_stem().unwrap().to_str().unwrap();
                let path_str = path.to_str().unwrap();
                let res = template_registry.register_template_file(&name, &path_str);
                if res.is_err() {
                    panic!("Could not register template: {:?}", res)
                }
            }
        }
    } else {
        panic!("Error extracting DirEntry: {:?}", entry)
    }
}
