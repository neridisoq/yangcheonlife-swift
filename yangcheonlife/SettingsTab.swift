import SwiftUI
import Firebase

struct SettingsTab: View {
    @State private var defaultGrade: Int = UserDefaults.standard.integer(forKey: "defaultGrade")
    @State private var defaultClass: Int = UserDefaults.standard.integer(forKey: "defaultClass")
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var selectedSubjectB: String = UserDefaults.standard.string(forKey: "selectedSubjectB") ?? "없음"
    @State private var selectedSubjectC: String = UserDefaults.standard.string(forKey: "selectedSubjectC") ?? "없음"
    @State private var selectedSubjectD: String = UserDefaults.standard.string(forKey: "selectedSubjectD") ?? "없음"
    @State private var cellBackgroundColor: Color = {
        if let data = UserDefaults.standard.data(forKey: "cellBackgroundColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            return Color(uiColor)
        }
        return Color.yellow.opacity(0.3)
    }()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(NSLocalizedString("Settings", comment: ""))) {
                    NavigationLink(NSLocalizedString("ClassSettings", comment: ""), destination: ClassAndGradeView(defaultGrade: $defaultGrade, defaultClass: $defaultClass, notificationsEnabled: $notificationsEnabled))
                    NavigationLink(NSLocalizedString("SubjectSelection", comment: ""), destination: SubjectSelectionView(selectedSubjectB: $selectedSubjectB, selectedSubjectC: $selectedSubjectC, selectedSubjectD: $selectedSubjectD))
                    ColorPicker(NSLocalizedString("ColorPicker", comment: ""), selection: $cellBackgroundColor)
                        .onChange(of: cellBackgroundColor) { newColor in
                            saveCellBackgroundColor(newColor)
                        }
                }
                
                Section(header: Text(NSLocalizedString("Link", comment: ""))) {
                    Link(NSLocalizedString("Privacy Policy", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr/dggb/module/policy/selectPolicyDetail.do?policyTypeCode=PLC002&menuNo=75574")!)
                    Link(NSLocalizedString("Goto School Web", comment: ""), destination: URL(string: "https://yangcheon.sen.hs.kr")!)
                }
                
                Section(header: Text(NSLocalizedString("Alert", comment: ""))) {
                    Toggle(NSLocalizedString("Alert Settings", comment: ""), isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { value in
                            UserDefaults.standard.set(value, forKey: "notificationsEnabled")
                            if value {
                                subscribeToCurrentTopic()
                            } else {
                                unsubscribeFromCurrentTopic()
                            }
                        }
                }
                
                Section(header: Text(NSLocalizedString("Support", comment: ""))) {
                    Button(action: {
                        sendEmail()
                    }) {
                        HStack {
                            Text(NSLocalizedString("Supportto", comment: ""))
                            Spacer()
                            Image(systemName: "envelope")
                        }
                    }
                }
            }
            .navigationBarTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSettings()
            if notificationsEnabled {
                subscribeToCurrentTopic()
            }
        }
    }
    
    private func loadSettings() {
        defaultGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
        defaultClass = UserDefaults.standard.integer(forKey: "defaultClass")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        selectedSubjectB = UserDefaults.standard.string(forKey: "selectedSubjectB") ?? "없음"
        selectedSubjectC = UserDefaults.standard.string(forKey: "selectedSubjectC") ?? "없음"
        selectedSubjectD = UserDefaults.standard.string(forKey: "selectedSubjectD") ?? "없음"
    }
    
    private func sendEmail() {
        let email = "neridisoq@icloud.com"
        if let url = URL(string: "mailto:\(email)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    private func subscribeToCurrentTopic() {
        let topic = "\(defaultGrade)-\(defaultClass)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Failed to subscribe to topic \(topic): \(error)")
            } else {
                print("Subscribed to topic \(topic)")
            }
        }
    }

    private func unsubscribeFromCurrentTopic() {
        let topic = "\(defaultGrade)-\(defaultClass)"
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Failed to unsubscribe from topic \(topic): \(error)")
            } else {
                print("Unsubscribed from topic \(topic)")
            }
        }
    }

    private func saveCellBackgroundColor(_ color: Color) {
        if let uiColor = UIColor(color).cgColor.copy(alpha: 0.3) {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(cgColor: uiColor), requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: "cellBackgroundColor")
            }
        }
    }
}

struct ClassAndGradeView: View {
    @Binding var defaultGrade: Int
    @Binding var defaultClass: Int
    @Binding var notificationsEnabled: Bool

    var body: some View {
        Form {
            Picker(NSLocalizedString("Grade", comment: ""), selection: $defaultGrade) {
                ForEach(1..<4) { grade in
                    Text(String(format: NSLocalizedString("GradeP", comment: ""), grade)).tag(grade)
                }
            }
            
            Picker(NSLocalizedString("Class", comment: ""), selection: $defaultClass) {
                ForEach(1..<12) { classNumber in
                    Text(String(format: NSLocalizedString("ClassP", comment: ""), classNumber)).tag(classNumber)
                }
            }
        }
        .navigationBarTitle(NSLocalizedString("ClassSettings", comment: ""), displayMode: .inline)
        .onDisappear {
            let oldGrade = UserDefaults.standard.integer(forKey: "defaultGrade")
            let oldClass = UserDefaults.standard.integer(forKey: "defaultClass")
            UserDefaults.standard.set(defaultGrade, forKey: "defaultGrade")
            UserDefaults.standard.set(defaultClass, forKey: "defaultClass")
            if notificationsEnabled {
                unsubscribeFromOldTopic(oldGrade: oldGrade, oldClass: oldClass)
                subscribeToCurrentTopic()
            }
        }
    }

    private func subscribeToCurrentTopic() {
        let topic = "\(defaultGrade)-\(defaultClass)"
        Messaging.messaging().subscribe(toTopic: topic) { error in
            if let error = error {
                print("Failed to subscribe to topic \(topic): \(error)")
            } else {
                print("Subscribed to topic \(topic)")
            }
        }
    }

    private func unsubscribeFromOldTopic(oldGrade: Int, oldClass: Int) {
        let topic = "\(oldGrade)-\(oldClass)"
        Messaging.messaging().unsubscribe(fromTopic: topic) { error in
            if let error = error {
                print("Failed to unsubscribe from topic \(topic): \(error)")
            } else {
                print("Unsubscribed from topic \(topic)")
            }
        }
    }
}

struct SubjectSelectionView: View {
    @Binding var selectedSubjectB: String
    @Binding var selectedSubjectC: String
    @Binding var selectedSubjectD: String
    let subjects = [
        "없음", "물리", "화학", "생명과학", "지구과학", "윤사", "정치와 법", "경제", "세계사", "한국지리", "탐구B", "탐구C", "탐구D"
    ]
    
    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("SubjectSelection", comment: ""))) {
                Picker(NSLocalizedString("Subject B", comment: ""), selection: $selectedSubjectB) {
                    ForEach(subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .onChange(of: selectedSubjectB) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "selectedSubjectB")
                }
                Picker(NSLocalizedString("Subject C", comment: ""), selection: $selectedSubjectC) {
                    ForEach(subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .onChange(of: selectedSubjectC) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "selectedSubjectC")
                }
                Picker(NSLocalizedString("Subject D", comment: ""), selection: $selectedSubjectD) {
                    ForEach(subjects, id: \.self) { subject in
                        Text(subject).tag(subject)
                    }
                }
                .onChange(of: selectedSubjectD) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "selectedSubjectD")
                }
            }
        }
        .navigationBarTitle("탐구 과목 선택", displayMode: .inline)
    }
}

struct SettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTab()
    }
}
