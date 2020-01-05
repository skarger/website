use dotenv;

pub fn load_env() {
    dotenv::from_filename(".env.test").ok();
}
