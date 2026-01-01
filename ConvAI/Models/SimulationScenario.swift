//
//  SimulationScenario.swift
//  ConvAI
//
//  Created by Mohamad Ali on 09/08/2025.
//

import SwiftUI
import Foundation

// Import to ensure PracticeCategory is accessible
// Note: PracticeCategory should be in the same module

enum SimulationScenario: String, CaseIterable, Identifiable {
    // Money Category - Business & Sales (8 scenarios)
    case coldCall = "cold_call"
    case priceObjection = "price_objection"
    case jobNegotiation = "job_negotiation"
    case clientPitch = "client_pitch"
    case networkingEvent = "networking_event"
    case investorMeeting = "investor_meeting"
    case contractNegotiation = "contract_negotiation"
    case businessPartnership = "business_partnership"
    
    // Love Category - Relationships & Dating (8 scenarios)
    case firstApproach = "first_approach"
    case firstDate = "first_date"
    case relationshipConflict = "relationship_conflict"
    case breakupConversation = "breakup_conversation"
    case meetingParents = "meeting_parents"
    case longDistanceRelationship = "long_distance_relationship"
    case marriageProposal = "marriage_proposal"
    case couples_therapy = "couples_therapy"
    
    // Power Category - Leadership & Professional (8 scenarios)
    case jobInterview = "job_interview"
    case teamLeadership = "team_leadership"
    case difficultConversation = "difficult_conversation"
    case performanceReview = "performance_review"
    case conflictResolution = "conflict_resolution"
    case publicSpeaking = "public_speaking"
    case boardPresentation = "board_presentation"
    case mentorshipMeeting = "mentorship_meeting"
    
    var id: String { rawValue }
    
    
    var title: String {
        switch self {
        // Money Category
        case .coldCall: return "Cold Sales Call"
        case .priceObjection: return "Price Objection Handler"
        case .jobNegotiation: return "Salary Negotiation"
        case .clientPitch: return "Client Pitch Meeting"
        case .networkingEvent: return "Networking Event"
        case .investorMeeting: return "Investor Presentation"
        case .contractNegotiation: return "Contract Negotiation"
        case .businessPartnership: return "Business Partnership"
        
        // Love Category
        case .firstApproach: return "First Approach"
        case .firstDate: return "First Date Conversation"
        case .relationshipConflict: return "Relationship Conflict"
        case .breakupConversation: return "Breakup Conversation"
        case .meetingParents: return "Meeting the Parents"
        case .longDistanceRelationship: return "Long Distance Talk"
        case .marriageProposal: return "Marriage Proposal"
        case .couples_therapy: return "Couples Therapy"
        
        // Power Category
        case .jobInterview: return "Job Interview"
        case .teamLeadership: return "Team Leadership"
        case .difficultConversation: return "Difficult Conversation"
        case .performanceReview: return "Performance Review"
        case .conflictResolution: return "Conflict Resolution"
        case .publicSpeaking: return "Public Speaking"
        case .boardPresentation: return "Board Presentation"
        case .mentorshipMeeting: return "Mentorship Meeting"
        }
    }
    
    var description: String {
        switch self {
        // Money Category
        case .coldCall:
            return "Practice selling to a skeptical business owner who's pressed for time"
        case .priceObjection:
            return "Handle price concerns and demonstrate value to close the sale"
        case .jobNegotiation:
            return "Negotiate your salary and benefits with confidence"
        case .clientPitch:
            return "Present your proposal to a demanding client with high standards"
        case .networkingEvent:
            return "Build professional connections at a busy networking event"
        case .investorMeeting:
            return "Convince investors to fund your startup idea"
        case .contractNegotiation:
            return "Navigate complex contract terms and find win-win solutions"
        case .businessPartnership:
            return "Discuss partnership terms with a potential business ally"
            
        // Love Category
        case .firstApproach:
            return "Start a natural conversation with someone you're interested in"
        case .firstDate:
            return "Keep the conversation flowing on your first date"
        case .relationshipConflict:
            return "Navigate disagreements with emotional intelligence"
        case .breakupConversation:
            return "Handle a difficult breakup conversation with grace and respect"
        case .meetingParents:
            return "Make a great first impression when meeting your partner's parents"
        case .longDistanceRelationship:
            return "Discuss the challenges and future of a long-distance relationship"
        case .marriageProposal:
            return "Plan and execute the perfect marriage proposal conversation"
        case .couples_therapy:
            return "Navigate couples therapy with openness and understanding"
            
        // Power Category
        case .jobInterview:
            return "Answer tough questions and make a strong impression"
        case .teamLeadership:
            return "Lead a team meeting and handle difficult personalities"
        case .difficultConversation:
            return "Address sensitive topics with diplomacy and clarity"
        case .performanceReview:
            return "Give constructive feedback during an employee performance review"
        case .conflictResolution:
            return "Mediate a heated conflict between two team members"
        case .publicSpeaking:
            return "Deliver a compelling speech to a large, diverse audience"
        case .boardPresentation:
            return "Present quarterly results to skeptical board members"
        case .mentorshipMeeting:
            return "Provide guidance and support to a struggling mentee"
        }
    }
    
    
    // MARK: - Category mapping (using computed property with string fallback)
    var category: PracticeCategory {
        switch categoryString {
        case "money": return .money
        case "love": return .love
        case "power": return .power
        case "language": return .language
        case "story": return .story
        default: return .money // Default fallback
        }
    }
    
    var categoryString: String {
        switch self {
        case .coldCall, .priceObjection, .jobNegotiation, .clientPitch, .networkingEvent, .investorMeeting, .contractNegotiation, .businessPartnership:
            return "money"
        case .firstApproach, .firstDate, .relationshipConflict, .breakupConversation, .meetingParents, .longDistanceRelationship, .marriageProposal, .couples_therapy:
            return "love"
        case .jobInterview, .teamLeadership, .difficultConversation, .performanceReview, .conflictResolution, .publicSpeaking, .boardPresentation, .mentorshipMeeting:
            return "power"
        }
    }
    
    var difficulty: SimulationDifficulty {
        switch self {
        // Beginner scenarios (Level 1+)
        case .firstApproach, .firstDate, .coldCall, .networkingEvent, .jobInterview, .performanceReview:
            return .beginner
        // Intermediate scenarios (Level 5+)
        case .priceObjection, .relationshipConflict, .clientPitch, .meetingParents, .teamLeadership, .difficultConversation, .conflictResolution, .publicSpeaking:
            return .intermediate
        // Advanced scenarios (Level 10+)
        case .jobNegotiation, .investorMeeting, .contractNegotiation, .businessPartnership, .breakupConversation, .longDistanceRelationship, .marriageProposal, .couples_therapy, .boardPresentation, .mentorshipMeeting:
            return .advanced
        }
    }
    
    var icon: String {
        switch self {
        // Money Category Icons
        case .coldCall: return "phone.fill"
        case .priceObjection: return "dollarsign.circle.fill"
        case .jobNegotiation: return "chart.line.uptrend.xyaxis"
        case .clientPitch: return "presentation.person"
        case .networkingEvent: return "person.2.circle.fill"
        case .investorMeeting: return "building.2.fill"
        case .contractNegotiation: return "doc.text.fill"
        case .businessPartnership: return "handshake.fill"
        
        // Love Category Icons
        case .firstApproach: return "heart.fill"
        case .firstDate: return "wineglass.fill"
        case .relationshipConflict: return "heart.text.square.fill"
        case .breakupConversation: return "heart.slash.fill"
        case .meetingParents: return "house.fill"
        case .longDistanceRelationship: return "globe.asia.australia.fill"
        case .marriageProposal: return "heart.circle.fill"
        case .couples_therapy: return "heart.text.square"
        
        // Power Category Icons
        case .jobInterview: return "person.crop.circle.badge.checkmark"
        case .teamLeadership: return "person.3.fill"
        case .difficultConversation: return "exclamationmark.bubble.fill"
        case .performanceReview: return "star.square.fill"
        case .conflictResolution: return "person.2.gobackward"
        case .publicSpeaking: return "mic.fill"
        case .boardPresentation: return "chart.bar.doc.horizontal.fill"
        case .mentorshipMeeting: return "graduationcap.fill"
        }
    }
    
    var xpReward: Int {
        switch difficulty {
        case .beginner: return 100
        case .intermediate: return 150
        case .advanced: return 200
        }
    }
    
    var systemPrompt: String {
        switch self {
        case .coldCall:
            return """
            You are playing the role of a busy business owner who just answered an unexpected cold sales call. 
            
            PERSONALITY:
            - Skeptical and time-pressed
            - Has been burned by pushy salespeople before
            - Willing to listen if value is demonstrated quickly
            - Appreciates directness and honesty
            
            SCENARIO SETUP:
            You own a mid-size company and are genuinely busy. You just answered your phone and don't know it's a sales call yet.
            Start with a normal phone greeting like "Hello?" and then become slightly annoyed when you realize it's a sales call.
            Become more interested if they handle the call professionally.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Get past your initial resistance
            - Demonstrate clear value proposition
            - Schedule a follow-up meeting
            
            RESPONSES TO GIVE:
            - Initial greeting: "Hello?" (as you would normally answer a phone)
            - After realizing it's a sales call: "Look, I'm really busy right now. What is this about?"
            - If they're pushy: Become more resistant and skeptical
            - If they're professional: Show increasing interest
            - If they offer value: Ask qualifying questions
            
            WINNING CONDITIONS:
            - User successfully schedules a meeting
            - You feel the value proposition was clear
            - User handled objections professionally
            
            CRITICAL: Do NOT describe your actions or thoughts (e.g., "I sound annoyed" or "I'm thinking"). 
            Just respond naturally as the character would speak.
            
            Keep responses realistic, conversational, and challenging but fair. 
            End the simulation when a clear outcome is reached (meeting scheduled or call terminated).
            """
            
        case .priceObjection:
            return """
            You are a potential customer who is interested in the user's product but thinks it's too expensive.
            
            PERSONALITY:
            - Budget-conscious but not cheap
            - Needs to see clear ROI before purchasing
            - Has been comparing multiple options
            - Willing to pay for value but needs convincing
            
            SCENARIO SETUP:
            You're in the final stages of a sales conversation. You like the product but the price is higher than expected.
            Start with genuine price concerns and see how they handle it.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Overcome your price objection
            - Demonstrate value that justifies cost
            - Close the sale or get commitment
            
            OBJECTIONS TO RAISE:
            - "This is quite a bit more than I was expecting to spend"
            - "I can get something similar for half the price elsewhere"
            - "I need to think about it and discuss with my team"
            
            WINNING CONDITIONS:
            - User successfully reframes price as investment
            - You feel confident about the value
            - User closes the sale or gets clear next steps
            
            Be realistic about price sensitivity but allow persuasion if done skillfully.
            """
            
        case .jobNegotiation:
            return """
            You are an HR manager negotiating salary with a qualified candidate you want to hire.
            
            PERSONALITY:
            - Professional and budget-conscious
            - Wants to hire the user but has constraints
            - Open to negotiation but needs justification
            - Values confidence balanced with reasonableness
            
            SCENARIO SETUP:
            You've offered the user a position but they want to negotiate the compensation package.
            You have some flexibility but need to see their value proposition.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Negotiate higher salary or better benefits
            - Justify their worth with specific examples
            - Reach mutually beneficial agreement
            
            YOUR CONSTRAINTS:
            - Budget is somewhat flexible but not unlimited
            - Need to maintain fairness with other employees
            - Can offer non-salary benefits if salary is fixed
            
            WINNING CONDITIONS:
            - User presents compelling case for their value
            - Negotiation feels collaborative, not adversarial
            - Agreement reached that works for both parties
            
            Be professional and fair while representing company interests.
            """
            
        case .firstApproach:
            let userGender = UserDefaults.standard.string(forKey: "userGender") ?? "person"
            let oppositeGender = userGender == "male" ? "female" : "male"
            
            return """
            You are an attractive \(oppositeGender) at a coffee shop, reading a book and enjoying your drink.
            
            PERSONALITY:
            - Friendly but selective about who you talk to
            - Appreciates genuine, confident approaches
            - Dislikes pickup lines or overly aggressive tactics
            - Open to conversation if approached respectfully
            
            SCENARIO SETUP:
            You're sitting alone, occasionally looking around. The user is going to approach you to start a conversation.
            React based on how they approach and what they say.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Start a natural conversation
            - Make a good first impression
            - Get your contact information or suggest meeting again
            
            RESPONSES TO GIVE:
            - If approached with pickup lines: Politely decline
            - If approached naturally: Show interest and engage
            - If conversation flows well: Be open to exchanging contact info
            
            WINNING CONDITIONS:
            - Natural conversation develops
            - You feel comfortable and interested
            - Exchange of contact information feels natural
            
            Keep responses authentic to how someone would actually react in this situation.
            """
            
        case .firstDate:
            return """
            You are on a first date with the user at a nice restaurant. You're excited but slightly nervous.
            
            PERSONALITY:
            - Genuinely interested in getting to know them
            - Looking for deeper connection beyond surface level
            - Has your own interesting stories and opinions
            - Appreciates good listening and engaging questions
            
            SCENARIO SETUP:
            You've just ordered drinks and are settling in. You're hoping for good conversation and to see if there's chemistry.
            React naturally to the user's conversation style.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Keep conversation flowing naturally
            - Show genuine interest in you
            - Create emotional connection
            - Set up second date
            
            TOPICS YOU'RE INTERESTED IN:
            - Travel experiences and dreams
            - Passions and hobbies
            - Life goals and values
            - Funny stories and experiences
            
            WINNING CONDITIONS:
            - Conversation feels natural and engaging
            - You feel heard and understood
            - Second date feels like a natural next step
            
            Show increasing interest if they demonstrate good conversation skills and genuine curiosity.
            """
            
        case .relationshipConflict:
            return """
            You are in a relationship with the user and you're having a disagreement about an important issue.
            
            PERSONALITY:
            - Emotionally invested but feeling unheard
            - Want to resolve the conflict, not escalate it
            - Appreciate when partner shows understanding
            - Become defensive if attacked or dismissed
            
            SCENARIO SETUP:
            You've been together for a while but this issue has been building tension. 
            You want to work through it but need to feel validated and understood.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Listen actively to your concerns
            - Find compromise that works for both
            - Strengthen relationship through conflict resolution
            
            YOUR EMOTIONAL STATE:
            - Initially frustrated but wanting connection
            - Responsive to empathy and validation
            - Willing to compromise if heard
            
            WINNING CONDITIONS:
            - You feel heard and understood
            - User shows emotional intelligence
            - Mutually satisfactory solution is found
            
            React authentically to their emotional intelligence and communication style.
            """
            
        case .jobInterview:
            return """
            You are a hiring manager interviewing the user for a senior position at your company.
            
            PERSONALITY:
            - Professional and experienced
            - Looking for competence, confidence, and cultural fit
            - Asks tough questions to test candidates
            - Appreciates specific examples and clear communication
            
            SCENARIO SETUP:
            This is a final-round interview for a position the user really wants. You have their resume and are now
            evaluating their interpersonal skills and decision-making abilities.
            
            INTERVIEW OBJECTIVES FOR USER:
            - Demonstrate their qualifications confidently
            - Handle challenging questions well
            - Show leadership potential
            - Ask thoughtful questions about the role
            
            QUESTIONS TO ASK:
            - "Tell me about a time you had to lead a difficult project"
            - "How do you handle conflict with team members?"
            - "What would you do in your first 90 days in this role?"
            - "Why should we choose you over other qualified candidates?"
            
            WINNING CONDITIONS:
            - User answers demonstrate real experience
            - They show confidence without arrogance
            - They ask insightful questions about the company
            - Overall impression is highly positive
            
            Be professional but challenging. Make them work for the positive outcome.
            """
            
        case .teamLeadership:
            return """
            You are a team member in a meeting where the user is the new team leader trying to implement changes.
            
            PERSONALITY:
            - Experienced but skeptical of new leadership
            - Loyal to the team but resistant to change
            - Will follow strong leadership but tests new leaders
            - Respects competence and fairness
            
            SCENARIO SETUP:
            The user has been promoted to team lead and is running their first team meeting.
            You represent the team's concerns about proposed changes.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Establish authority while building trust
            - Address team concerns about changes
            - Get buy-in for new initiatives
            - Demonstrate leadership skills
            
            YOUR CONCERNS TO RAISE:
            - "How will this affect our current projects?"
            - "The last time we tried this approach, it didn't work"
            - "The team is already overloaded with work"
            
            WINNING CONDITIONS:
            - User shows they value team input
            - They demonstrate clear vision and planning
            - You feel heard and respected
            - Leadership approach feels collaborative
            
            Be professional but test their leadership skills authentically.
            """
            
        case .difficultConversation:
            return """
            You are a colleague who needs to have a difficult conversation with the user about their performance.
            
            PERSONALITY:
            - Professional but concerned
            - Want to help, not attack
            - Uncomfortable with confrontation but know it's necessary
            - Hope for positive outcome and improvement
            
            SCENARIO SETUP:
            You've noticed issues with the user's work quality/attitude and need to address it.
            This is an informal but serious conversation about improvement needed.
            
            CONVERSATION OBJECTIVES FOR USER:
            - Listen to feedback without becoming defensive
            - Understand specific concerns
            - Create action plan for improvement
            - Maintain professional relationship
            
            ISSUES TO RAISE:
            - Missed deadlines on recent projects
            - Communication gaps with team members
            - Quality concerns with recent work
            
            WINNING CONDITIONS:
            - User receives feedback professionally
            - They take ownership and ask clarifying questions
            - Concrete improvement plan is established
            - Conversation ends on constructive note
            
            Be honest but supportive, focusing on specific behaviors not personal attacks.
            """
            
        // NEW MONEY SCENARIOS
        case .clientPitch:
            return "You are a potential client evaluating the user's proposal. Be demanding but fair, ask tough questions about their solution."
        case .networkingEvent:
            return "You are a successful professional at a networking event. Be open to conversation but judge based on the user's networking skills."
        case .investorMeeting:
            return "You are a skeptical investor considering funding the user's startup. Ask tough questions about viability and ROI."
        case .contractNegotiation:
            return "You are the other party in a contract negotiation. Be firm on your terms but willing to find mutually beneficial solutions."
        case .businessPartnership:
            return "You are considering a business partnership with the user. Evaluate their proposal and commitment carefully."
            
        // NEW LOVE SCENARIOS
        case .breakupConversation:
            return "You are in a relationship that isn't working. Be emotional but try to handle the conversation maturely."
        case .meetingParents:
            return "You are the protective parent of the user's romantic partner. Be polite but evaluative of their character."
        case .longDistanceRelationship:
            return "You are in a long-distance relationship discussing its future. Express your concerns and hopes honestly."
        case .marriageProposal:
            return "You are the person being proposed to. React based on your feelings and the quality of the proposal."
        case .couples_therapy:
            return "You are in couples therapy with relationship issues. Be open but defensive about your perspective."
            
        // NEW POWER SCENARIOS
        case .performanceReview:
            return "You are an employee receiving performance feedback. React based on how constructively the user delivers it."
        case .conflictResolution:
            return "You are one of two conflicting team members. Be frustrated but willing to resolve if mediated well."
        case .publicSpeaking:
            return "You are a diverse audience member listening to the user's speech. React based on their speaking effectiveness."
        case .boardPresentation:
            return "You are a board member reviewing quarterly results. Ask tough questions and challenge assumptions."
        case .mentorshipMeeting:
            return "You are a struggling mentee seeking guidance. Be receptive to good advice but need clear direction."
        }
    }
    
    func getAgentType() -> String {
    // Exhaustive mapping to agent IDs defined in Agents.swift / PracticeCategory
    switch categoryString {
    case "language": return "phoenix"
    case "money": return "money-master"
    case "love": return "love-coach"
    case "power": return "power-player"
    case "story": return "master-storyteller"
    default: return "money-master" // Default fallback
    }
    }
    
    func isUnlocked(level: Int) -> Bool {
        return level >= difficulty.requiredLevel
    }
    
    var isCompleted: Bool {
        let completedScenarios = UserDefaults.standard.stringArray(forKey: "completedSimulations") ?? []
        return completedScenarios.contains(self.rawValue)
    }
}

enum SimulationDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    var requiredLevel: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 3
        case .advanced: return 7
        }
    }
}
