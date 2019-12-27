pub use handlebars::Handlebars;

pub fn register_templates<'a>() -> Handlebars<'a> {
    let mut template_registry = Handlebars::new();
    template_registry.set_strict_mode(true);
    let res =
        template_registry.register_template_file("application", "./src/templates/partials/application.hbs")
            .and_then(|_| { template_registry.register_template_file("header", "./src/templates/partials/header.hbs") })
            .and_then(|_| { template_registry.register_template_file("home", "./src/templates/home.hbs") })
            .and_then(|_| { template_registry.register_template_file("404", "./src/templates/404.hbs") })
            .and_then(|_| { template_registry.register_template_file("messages", "./src/templates/messages.hbs") })
            .and_then(|_| { template_registry.register_template_file("about", "./src/templates/about.hbs") });
    match res {
        Ok(_) => { },
        Err(tfe) => {
            panic!("Could not register template: {}", tfe)
        }
    }

    template_registry
}
