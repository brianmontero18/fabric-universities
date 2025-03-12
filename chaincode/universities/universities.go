package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type Student struct {
	ID                   string           `json:"id"`
	Name                 string           `json:"name"`
	CurrentUniversity    string           `json:"currentUniversity"`
	PreviousUniversities []string         `json:"previousUniversities"`
	EnrollmentDate       string           `json:"enrollmentDate"`
	Status               string           `json:"status"` // Active, Transferred, Graduated
	AcademicRecords      []AcademicRecord `json:"academicRecords"`
	PersonalInfo         PersonalInfo     `json:"personalInfo"`
}

type PersonalInfo struct {
	Email       string `json:"email"`
	Phone       string `json:"phone"`
	Address     string `json:"address"`
	Nationality string `json:"nationality"`
}

type AcademicRecord struct {
	University string  `json:"university"`
	Course     string  `json:"course"`
	Grade      float64 `json:"grade"`
	Period     string  `json:"period"`
	Credits    int     `json:"credits"`
	Status     string  `json:"status"` // Completed, In Progress, Failed
}

func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	return nil
}

// RegisterStudent creates a new student record
func (s *SmartContract) RegisterStudent(ctx contractapi.TransactionContextInterface, id string, name string, university string, enrollmentDate string, personalInfo PersonalInfo) error {
	exists, err := s.StudentExists(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to verify student existence: %v", err)
	}
	if exists {
		return fmt.Errorf("student already exists: %s", id)
	}

	student := Student{
		ID:                   id,
		Name:                 name,
		CurrentUniversity:    university,
		PreviousUniversities: []string{},
		EnrollmentDate:       enrollmentDate,
		Status:               "Active",
		AcademicRecords:      []AcademicRecord{},
		PersonalInfo:         personalInfo,
	}

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return fmt.Errorf("failed to marshal student data: %v", err)
	}

	return ctx.GetStub().PutState(id, studentJSON)
}

// TransferStudent transfers a student to another university
func (s *SmartContract) TransferStudent(ctx contractapi.TransactionContextInterface, studentId string, newUniversity string, transferDate string) error {
	student, err := s.GetStudent(ctx, studentId)
	if err != nil {
		return fmt.Errorf("failed to get student: %v", err)
	}

	if student.Status != "Active" {
		return fmt.Errorf("student is not in active status")
	}

	student.PreviousUniversities = append(student.PreviousUniversities, student.CurrentUniversity)
	student.CurrentUniversity = newUniversity
	student.Status = "Transferred"

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return fmt.Errorf("failed to marshal student data: %v", err)
	}

	return ctx.GetStub().PutState(studentId, studentJSON)
}

// AddAcademicRecord adds a new academic record to a student's history
func (s *SmartContract) AddAcademicRecord(ctx contractapi.TransactionContextInterface, studentId string, record AcademicRecord) error {
	student, err := s.GetStudent(ctx, studentId)
	if err != nil {
		return fmt.Errorf("failed to get student: %v", err)
	}

	if student.Status != "Active" && student.Status != "Transferred" {
		return fmt.Errorf("cannot add academic record: student is not active or transferred")
	}

	student.AcademicRecords = append(student.AcademicRecords, record)

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return fmt.Errorf("failed to marshal student data: %v", err)
	}

	return ctx.GetStub().PutState(studentId, studentJSON)
}

// GetStudent returns the student stored in the world state with given id
func (s *SmartContract) GetStudent(ctx contractapi.TransactionContextInterface, id string) (*Student, error) {
	studentJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read student data: %v", err)
	}
	if studentJSON == nil {
		return nil, fmt.Errorf("student not found: %s", id)
	}

	var student Student
	err = json.Unmarshal(studentJSON, &student)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal student data: %v", err)
	}

	return &student, nil
}

// GetStudentsByUniversity returns all students from a specific university
func (s *SmartContract) GetStudentsByUniversity(ctx contractapi.TransactionContextInterface, university string) ([]*Student, error) {
	queryString := fmt.Sprintf(`{"selector":{"currentUniversity":"%s"}}`, university)

	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, fmt.Errorf("failed to get students: %v", err)
	}
	defer resultsIterator.Close()

	var students []*Student
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to get next student: %v", err)
		}

		var student Student
		err = json.Unmarshal(queryResponse.Value, &student)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal student data: %v", err)
		}
		students = append(students, &student)
	}

	return students, nil
}

// GetAllStudents returns all students found in world state
func (s *SmartContract) GetAllStudents(ctx contractapi.TransactionContextInterface) ([]*Student, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get all students: %v", err)
	}
	defer resultsIterator.Close()

	var students []*Student
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to get next student: %v", err)
		}

		var student Student
		err = json.Unmarshal(queryResponse.Value, &student)
		if err != nil {
			return nil, fmt.Errorf("failed to unmarshal student data: %v", err)
		}
		students = append(students, &student)
	}

	return students, nil
}

// StudentExists returns true when student with given ID exists in world state
func (s *SmartContract) StudentExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	studentJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read student data: %v", err)
	}

	return studentJSON != nil, nil
}

// UpdateStudentStatus updates the status of a student
func (s *SmartContract) UpdateStudentStatus(ctx contractapi.TransactionContextInterface, studentId string, newStatus string) error {
	student, err := s.GetStudent(ctx, studentId)
	if err != nil {
		return fmt.Errorf("failed to get student: %v", err)
	}

	if newStatus != "Active" && newStatus != "Transferred" && newStatus != "Graduated" {
		return fmt.Errorf("invalid status: %s", newStatus)
	}

	student.Status = newStatus

	studentJSON, err := json.Marshal(student)
	if err != nil {
		return fmt.Errorf("failed to marshal student data: %v", err)
	}

	return ctx.GetStub().PutState(studentId, studentJSON)
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating universities chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting universities chaincode: %s", err.Error())
	}
}
