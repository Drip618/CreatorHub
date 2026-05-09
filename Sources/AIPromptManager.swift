import Foundation
import AppKit

class AIPromptManager: ObservableObject {
    static let shared = AIPromptManager()
    
    func transformClipboard() -> String? {
        let pb = NSPasteboard.general
        guard let text = pb.string(forType: .string), !text.isEmpty else { return nil }
        
        let prompt = """
        # Role: Professional Prompt Engineer
        # Context: User provided a rough description and needs a high-quality, structured AI prompt.
        
        # Original Input:
        "\(text)"
        
        # Structured Prompt:
        You are an expert in [Topic]. Your task is to [Goal based on input].
        
        ## Objectives:
        - [Primary Objective]
        - [Secondary Detail]
        
        ## Constraints & Style:
        - Maintain a [Tone] tone.
        - Ensure [Constraint].
        
        ## Output Format:
        [Specify Format]
        
        Please proceed with this instruction.
        """
        
        pb.clearContents()
        pb.setString(prompt, forType: .string)
        return "提示词已专业化并复制"
    }
}
