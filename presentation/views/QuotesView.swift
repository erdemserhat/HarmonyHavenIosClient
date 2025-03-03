                                    // Reset the scroll timer
                                    scrollTimer?.invalidate()
                                    scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                                        
                                        self.isScrolling = false
                                        
                                        // Resume video playback for the currently visible quote
                                        if let activeId = self.activeVideoQuoteId, self.visibleQuoteIds.contains(activeId) {
                                            // Find the quote and play its video
                                            if let quote = self.viewModel.quotes.first(where: { $0.id == activeId }) {
                                                // Set the ID to scroll to, which will trigger the onChange handler
                                                self.scrollToId = activeId
                                            }
                                        }
                                    } 