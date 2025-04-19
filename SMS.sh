#!/bin/bash

STUDENT_FILE="students.txt"
BACKUP_FILE="students_backup.txt"

# Teacher credentials
TEACHER_USERNAME="Main"
TEACHER_PASSWORD="1234_5"

# Store the student roll number for the session
logged_in_student=""

# Main menu
main_menu() {
    while true; do
        echo -e "\nMain Menu"
        echo "1. Teacher"
        echo "2. Student"
        echo "3. Exit"
        echo -n "Enter choice: "
        read choice

        case $choice in
            1) teacher_menu ;;
            2) student_menu ;;
            3) exit 0 ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}

# Teacher menu (requires login)
teacher_menu() {
    if ! teacher_login; then
        return
    fi

    while true; do
        echo -e "\nTeacher Menu"
        echo "1. Add Student"
        echo "2. Delete Student"
        echo "3. Assign Marks"
        echo "4. Calculate Grades"
        echo "5. Update Student Info"
        echo "6. List Passed Students"
        echo "7. List Failed Students"
        echo "8. Sort Students"
        echo "9. Generate Report"
        echo "10. Backup & Restore Data"
        echo "11. Back to Main Menu"
        echo -n "Enter choice: "
        read choice

        case $choice in
            1) add_student ;;
            2) delete_student ;;
            3) assign_marks ;;
            4) calculate_grades ;;
            5) update_student ;;
            6) list_passed ;;
            7) list_failed ;;
            8) sort_students ;;
            9) generate_report ;;
            10) backup_restore_data ;;
            11) return ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}

# Login for teacher
teacher_login() {
    echo -n "Enter Teacher Username: "
    read username
    echo -n "Enter Teacher Password: "
    read -s password
    echo

    if [[ "$username" == "$TEACHER_USERNAME" && "$password" == "$TEACHER_PASSWORD" ]]; then
        echo "Login successful."
        return 0
    else
        echo "Invalid credentials."
        return 1
    fi
}

# Student menu
student_menu() {
    if [ -z "$logged_in_student" ]; then
        echo "You must log in first!"
        student_login
    fi

    while true; do
        echo -e "\nStudent Menu"
        echo "1. View Grades"
        echo "2. View CGPA"
        echo "3. Back to Main Menu"
        echo -n "Enter choice: "
        read choice

        case $choice in
            1) view_grades ;;
            2) view_cgpa ;;
            3) logged_in_student=""  # Log out automatically when going back to the main menu
               return ;;
            *) echo "Invalid choice!" ;;
        esac
    done
}
# Add new student (max 20 students)
add_student() {
    student_count=$(wc -l < "$STUDENT_FILE")
    if (( student_count >= 20 )); then
        echo "Cannot add more than 20 students."
        return
    fi

    echo -n "Enter Roll No: "
    read roll_no
    if grep -q "^$roll_no," "$STUDENT_FILE"; then
        echo "Student already exists."
        return
    fi

    echo -n "Enter Name: "
    read name
    echo "$roll_no,$name,0,0,0,0,0,N/A,0.0" >> "$STUDENT_FILE"
    echo "Student added."
}

# Delete student by roll number
delete_student() {
    echo -n "Enter Roll No to delete: "
    read roll_no
    grep -v "^$roll_no," "$STUDENT_FILE" > temp.txt && mv temp.txt "$STUDENT_FILE"
    echo "Student deleted."
}

# Assign marks for subjects
assign_marks() {
    echo -n "Enter Roll No: "
    read roll_no

    while true; do
        echo -e "\nAssign Marks Menu"
        echo "1. Math"
        echo "2. Science"
        echo "3. English"
        echo "4. History"
        echo "5. Computer"
        echo "6. Exit"
        echo -n "Enter choice: "
        read subject_index

        if [[ "$subject_index" -eq 6 ]]; then
            break
        fi

        if (( subject_index < 1 || subject_index > 5 )); then
            echo "Invalid choice!"
            continue
        fi

        while true; do
            echo -n "Enter Marks (0-100): "
            read marks
            if [[ "$marks" =~ ^[0-9]+$ ]] && (( marks >= 0 && marks <= 100 )); then
                break
            else
                echo "Invalid marks!"
            fi
        done

        while IFS=',' read -r rno name m1 m2 m3 m4 m5 grade gpa; do
            if [[ "$rno" == "$roll_no" ]]; then
                case "$subject_index" in
                    1) m1=$marks ;;
                    2) m2=$marks ;;
                    3) m3=$marks ;;
                    4) m4=$marks ;;
                    5) m5=$marks ;;
                esac
            fi
            echo "$rno,$name,$m1,$m2,$m3,$m4,$m5,$grade,$gpa" >> temp.txt
        done < "$STUDENT_FILE"

        mv temp.txt "$STUDENT_FILE"
        echo "Marks updated."
    done
}

# Calculate grades and CGPA
calculate_grades() {
    > temp.txt
    while IFS=',' read -r rno name m1 m2 m3 m4 m5 _; do
        total=$((m1 + m2 + m3 + m4 + m5))
        avg=$((total / 5))

        if (( avg >= 90 )); then grade="A"; gpa=4.0
        elif (( avg >= 85 )); then grade="A-"; gpa=3.7
        elif (( avg >= 80 )); then grade="B+"; gpa=3.3
        elif (( avg >= 75 )); then grade="B"; gpa=3.0
        elif (( avg >= 70 )); then grade="B-"; gpa=2.7
        elif (( avg >= 65 )); then grade="C+"; gpa=2.3
        elif (( avg >= 60 )); then grade="C"; gpa=2.0
        elif (( avg >= 55 )); then grade="C-"; gpa=1.7
        elif (( avg >= 50 )); then grade="D+"; gpa=1.3
        elif (( avg >= 45 )); then grade="D"; gpa=1.0
        else grade="F"; gpa=0.0
        fi

        echo "$rno,$name,$m1,$m2,$m3,$m4,$m5,$grade,$gpa" >> temp.txt
    done < "$STUDENT_FILE"

    mv temp.txt "$STUDENT_FILE"
    echo "Grades calculated."
}

# Update student details
update_student() {
    echo -n "Enter Roll No to update: "
    read roll_no

    if ! grep -q "^$roll_no," "$STUDENT_FILE"; then
        echo "Student not found."
        return
    fi

    echo -n "Enter New Name: "
    read new_name
    echo -n "Enter New Marks for Math: "; read new_m1
    echo -n "Enter New Marks for Science: "; read new_m2
    echo -n "Enter New Marks for English: "; read new_m3
    echo -n "Enter New Marks for History: "; read new_m4
    echo -n "Enter New Marks for Computer: "; read new_m5

    while IFS=',' read -r rno name m1 m2 m3 m4 m5 grade gpa; do
        if [[ "$rno" == "$roll_no" ]]; then
            [[ -n "$new_name" ]] && name="$new_name"
            [[ -n "$new_m1" ]] && m1="$new_m1"
            [[ -n "$new_m2" ]] && m2="$new_m2"
            [[ -n "$new_m3" ]] && m3="$new_m3"
            [[ -n "$new_m4" ]] && m4="$new_m4"
            [[ -n "$new_m5" ]] && m5="$new_m5"
        fi
        echo "$rno,$name,$m1,$m2,$m3,$m4,$m5,$grade,$gpa" >> temp.txt
    done < "$STUDENT_FILE"

    mv temp.txt "$STUDENT_FILE"
    echo "Student updated."
}

# Generate student report
generate_report() {
    echo -e "\nStudent Report:"
    echo "---------------------------------------------------------------------------------------------"
    printf "%-5s | %-10s | %-20s | %-5s | %-5s | %-5s | %-5s | %-5s | %-6s | %-4s\n" "No." "Roll No" "Name" "M1" "M2" "M3" "M4" "M5" "Grade" "CGPA"
    echo "---------------------------------------------------------------------------------------------"

    count=1
    while IFS=',' read -r rno name m1 m2 m3 m4 m5 grade gpa; do
        printf "%-5s | %-10s | %-20s | %-5s | %-5s | %-5s | %-5s | %-5s | %-6s | %-4s\n" "$count" "$rno" "$name" "$m1" "$m2" "$m3" "$m4" "$m5" "$grade" "$gpa"
        ((count++))
    done < "$STUDENT_FILE"
}


# Backup or restore student data
backup_restore_data() {
    echo "1. Backup Data"
    echo "2. Restore Data"
    echo -n "Choose option: "
    read option
    case $option in
        1) cp "$STUDENT_FILE" "$BACKUP_FILE" && echo "Backup created." ;;
        2) cp "$BACKUP_FILE" "$STUDENT_FILE" && echo "Data restored." ;;
        *) echo "Invalid option!" ;;
    esac
}

# List students who passed
list_passed() {
    echo -e "\nPassed Students:"
    echo "------------------------------------------------------------"
    printf "%-5s | %-10s | %-20s | %-6s | %-4s\n" "No." "Roll No" "Name" "Grade" "CGPA"
    echo "------------------------------------------------------------"

    count=1
    while IFS=',' read -r rno name m1 m2 m3 m4 m5 grade gpa; do
        if [[ "$grade" != "F" ]]; then
            printf "%-5s | %-10s | %-20s | %-6s | %-4s\n" "$count" "$rno" "$name" "$grade" "$gpa"
            ((count++))
        fi
    done < "$STUDENT_FILE"
}


# List students who failed
list_failed() {
    echo -e "\nFailed Students:"
    echo "------------------------------------------------------------"
    printf "%-5s | %-10s | %-20s | %-6s | %-4s\n" "No." "Roll No" "Name" "Grade" "CGPA"
    echo "------------------------------------------------------------"

    count=1
    while IFS=',' read -r rno name m1 m2 m3 m4 m5 grade gpa; do
        if [[ "$grade" == "F" ]]; then
            printf "%-5s | %-10s | %-20s | %-6s | %-4s\n" "$count" "$rno" "$name" "$grade" "$gpa"
            ((count++))
        fi
    done < "$STUDENT_FILE"
}

# Sort students by CGPA (desc)
sort_students() {
    sort -t',' -k9 -nr "$STUDENT_FILE" -o "$STUDENT_FILE"
    echo "Students sorted by CGPA."
}

student_login() {
    # Check if the student is already logged in
    if [ -n "$logged_in_student" ]; then
        echo "You are already logged in as Roll No $logged_in_student."
        return
    fi

    echo -n "Enter Roll No: "
    read roll_no

    # Verify the student exists in the file
    if ! grep -q "^$roll_no," "$STUDENT_FILE"; then
        echo "Student with Roll No $roll_no not found."
        return
    fi

    logged_in_student="$roll_no"
    echo "Login successful as Roll No $logged_in_student."
}

# View grades by roll number
view_grades() {
    if [ -z "$logged_in_student" ]; then
        echo "Please log in first!"
        return
    fi

    result=$(grep "^$logged_in_student," "$STUDENT_FILE")

    if [ -z "$result" ]; then
        echo "Student with Roll No $logged_in_student not found."
        return
    fi

    IFS=',' read -r rno name m1 m2 m3 m4 m5 grade gpa <<< "$result"

    echo -e "\nGrades for $name (Roll No: $rno):"
    echo "----------------------------------"
    echo "Math       : $m1"
    echo "Science    : $m2"
    echo "English    : $m3"
    echo "History    : $m4"
    echo "Computer   : $m5"
    echo "Final Grade: $grade"
}

# View CGPA by roll number
view_cgpa() {
    if [ -z "$logged_in_student" ]; then
        echo "Please log in first!"
        return
    fi

    result=$(grep "^$logged_in_student," "$STUDENT_FILE")

    if [ -z "$result" ]; then
        echo "Student with Roll No $logged_in_student not found."
        return
    fi

    IFS=',' read -r rno name _ _ _ _ _ grade cgpa <<< "$result"

    echo -e "\nStudent: $name (Roll No: $rno)"
    echo "Final Grade: $grade"
    echo "CGPA: $cgpa"
}

# Start the app
main_menu
