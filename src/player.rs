// ...existing code...
pub struct Player {
    // ...existing code...
    pub debug_immortal: bool,
    // ...existing code...
}

impl Player {
    // ...existing code...
    pub fn new(position: Point) -> Self {
        Self {
            // ...existing code...
            debug_immortal: false,
            // ...existing code...
        }
    }
    
    // ...existing code...
    
    pub fn toggle_debug_immortal(&mut self) {
        self.debug_immortal = !self.debug_immortal;
    }
    
    pub fn is_debug_immortal(&self) -> bool {
        self.debug_immortal
    }
    
    // ...existing code...
}
