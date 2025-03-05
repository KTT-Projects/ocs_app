# Osakikamijima Student Community Site

## Overview

This site is a community platform for students enrolled in educational institutions on Osakikamijima. It aims to facilitate student interactions, event planning and participation, volunteer activities, and peer learning.

## Key Features

### User Management

- User Registration & Login
- Only students can register (Verification via educational institution email or student ID)
- Teacher and administrator accounts can also be created
- Profile Management
  - Name (nickname allowed)
  - School name & grade
  - Interests & skills (e.g., sports, programming)
  - Volunteer & event participation history
  - Contact options (in-site DM, email)

### Interaction Features

- Bulletin Board
  - Categories (General discussion, study, events, volunteering)
  - Comment & reply system
  - Image & file attachments
- Direct Messaging
  - One-on-one chat
  - Group chat
- Feed System
  - Users can post updates (supports images & videos)
  - “Like,” comment, and share functions

### Event Management

- Event Creation
  - Event name, date, location, and description
  - Participant management
  - Google Calendar integration
- Event Search & Participation
  - Category search (Study sessions, sports, cultural activities, volunteering)
  - Join & cancel participation

### Volunteer Activities

- Volunteer Recruitment
  - Requests can be posted by local residents, municipalities, and schools
  - Participant list management
- Activity Records
  - Volunteer participation history
  - Certificate issuance (downloadable as PDF)

### Study Support

- Q&A Forum
  - Question & answer system (best answer selection)
  - Mathematical formulas supported (LaTeX notation)
- Tutor System
  - Tutors can register by grade & subject
  - Matching system for students and tutors
  - Online video calls (integrated with external tools)

### Notifications & Administration

- Push & Email Notifications
  - Event reminders
  - New messages & replies
- Administrator Dashboard
  - User management
  - Monitoring & removal of inappropriate content
  - Access analytics

## Technology Stack

- Frontend (App Version): Flutter (Supports iOS / Android)
- Frontend (Web Version): Flutter Web (Hosted on your own web server)
- Backend: Hosted on your own web server (PHP)
- Database: SQL database on your own web server (MySQL)
- Storage: Uses your own web server’s storage (For images and file management)
- Authentication:
  - Educational institution email verification
  - Student ID upload for verification (Approval required by administrators)
- Deployment:
  - App version (App Store / Google Play)
  - Web version (Hosted on your own web server)

## Operations & Management

- Administrators: School staff + student volunteers
- Moderation Policy
  - Users can report inappropriate posts
  - Site terms of use & community guidelines will be established
- Security Measures
  - HTTPS encryption
  - User data encryption
  - Minimized storage of personal information
