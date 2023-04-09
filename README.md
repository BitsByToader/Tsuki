# Tsuki
A beautiful and simple manga app for iOS 14, iPadOS 14 and macOS 11, built with SwiftUI.

# Features
- Easy to use UI, with an Apple-y aesthetic
- Rich manga library pulled from MangaDex
- Seamless library syncing with your MangaDex account
- Intuitive search with tag inclusion and exclusion
- Save manga chapters for offline reading
- Widgets!
- Logging in to your MangaDex account couldn't be easier. No more going back and forth to a browser view!
- Beautiful iPadOS and macOS (I still have to test this when macOS 11 drops) app

# Upcoming features
- Siri shortcuts
- Recents! Quickly see your reading history!
- Drag and drop chapter pages for quick sharing with your friends
- Saving chapter pages to your photos library
- Easily share mangas and chapters with your friends
- More and Better Localization!
- Better navigation for iPad users
- Supporting multiple manga providers, besides MangaDex
- *bug fixes and minor improvements...*

# AppStore status
  The app hasn't been accepted to the AppStore because of the content it provides. Because of this, it has also been shadow banned from TestFlight, meaning the public link doesn't work anymore (i.e. manual invites are the only way to get added to the TestFlight). However, since making it mandatory to provide an API URL when logging in, Tsuki might get approved to the AppStore, but I am far to tired to even try.

# Bugs and other issues
It has been almost three years (aka final year of high school, so didn't have much experience at the time) and a few SwiftUI versions since I started this project, so when I look back at the codebase I feel it is lacking from multiple points of view. There are also a couple of things that aren't quite finished (like chapter saving which has two major bug which are left in TODOs), but I'm too burnt out to fix them. As such, be kind when looking through the code if you plan on contributing :).

Another thing to note is that MangaDex is planning on disabling the current login scheme and switching over to OAuth. As such, Tsuki will have to switch as well if it wants to stay alive, besides implementing the features in the *Upcoming features* list and switching to the latest SwiftUI version.

As such, I'll look forward to accepting any upcoming PRs.
