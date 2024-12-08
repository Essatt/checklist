# Checklist
### Video Demo:  https://youtu.be/bcZUduyOhNI
### Description:
Checklist is a Flutter app that allows the user to create checklist templates, activate the checklists, complete the checklists, see after who did the checklist, which tasks were all completed and how long it took.

I had this idea when I saw a documentary on surgical mistakes and them being drastically reduced by the usage of checklists. I tried to create a minimal MVP version of a digital checklist system for a hospital.

#### What Does This App Do?

The app has three main sections:

1. **Templates**: This is where you create and store your checklist templates. Think of these like blank forms that you can use again and again. Each template has a title and a list of steps that need to be completed.

2. **Active**: When you want to use a template, you "activate" it. In the Active section, you can see all the checklists that are currently being worked on. You can check off items as you complete them, and see how long the process has been running.

3. **Archive**: After a checklist is completed, it moves to the Archive. Here you can see the full history - who completed it, how long it took, which steps were checked off, and when each step was completed.

#### How I Built It

I used Flutter because it lets me create apps that work on both iPhone and Android. Here are the main files I created and what they do:

#### Files in the `models` folder:
- `checklist_model.dart`: This is the brain of the app. It handles all the data about checklists, how they're saved, and how they're loaded. I decided to use SharedPreferences to store the data locally on the phone instead of a server to keep things simple for this MVP.

#### Files in the `screens` folder:
- `templates_screen.dart`: Shows all your templates and lets you create new ones
- `active_checklists_screen.dart`: Shows checklists that are currently being worked on
- `archived_checklists_screen.dart`: Shows completed checklists
- `create_checklist_screen.dart`: The screen where you make new templates
- `checklist_screen.dart`: Where you actually work through a checklist

#### Files in the `utils` folder:
- `date_time_utils.dart`: Helps format dates and times in a nice way
- `dialog_utils.dart`: Handles all the pop-up messages and confirmations

#### Design Choices I Made

1. **Local Storage**: I chose to store everything on the phone using SharedPreferences instead of a server. This makes the app simpler and means it works without internet, which could be important in a hospital setting.

2. **Three-Tab Design**: I split the app into Templates, Active, and Archive because this matches how people actually use checklists - you create a template once, use it many times, and want to keep a record of completed checklists.

3. **Flexible Completion**: I made it possible to complete a checklist even if not every item is checked. In real life, sometimes certain steps might not apply, or might be handled differently. The app still shows which steps were and weren't completed in the archive.

4. **Timestamps**: I added timestamps for when each step is completed and how long the whole process takes. This helps track efficiency and could help identify where processes are getting stuck.

#### What I Learned

Building this app taught me a lot about state management in Flutter (using Provider), working with dates and times, and designing a user-friendly interface. The biggest challenge was managing the different states a checklist can be in (template, active, archived) and making sure the data stays consistent as checklists move between these states.

#### Future Improvements

If I were to expand this MVP, I would add:
- User accounts and roles (admin, regular user)
- Cloud storage to share checklists between devices
- Statistics and reports about completion times
- Categories for different types of checklists
- The ability to add photos or notes to checklist items

The current version focuses on the core functionality of creating and using checklists, but there's a lot of potential to add features that would make it more useful in a real healthcare setting.
