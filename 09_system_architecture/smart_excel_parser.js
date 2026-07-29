/**
 * Smart Excel Parser - Intelligently maps Excel columns to database fields
 */
class SmartExcelParser {
    constructor() {
        // Column mapping patterns
        this.columnPatterns = {
            student_number: [
                /student\s*(?:number|id|no|#)/i,
                /reg\s*(?:number|id|no|#)/i,
                /adm\s*(?:number|id|no|#)/i,
                /registration/i,
                /admission/i
            ],
            first_name: [
                /first\s*(?:name|nimi)/i,
                /given\s*name/i,
                /forename/i,
                /fname/i,
                /first/i
            ],
            last_name: [
                /last\s*(?:name|nimi)/i,
                /surname/i,
                /family\s*name/i,
                /lname/i,
                /last/i
            ],
            middle_name: [
                /middle\s*(?:name|nimi)/i,
                /middlename/i,
                /mname/i,
                /middle/i
            ],
            full_name: [
                /full\s*(?:name|nimi)/i,
                /student\s*name/i,
                /name/i
            ],
            email: [
                /email/i,
                /e-mail/i,
                /mail/i
            ],
            phone: [
                /phone/i,
                /mobile/i,
                /cell/i,
                /telephone/i,
                /contact/i
            ],
            programme: [
                /programme/i,
                /program/i,
                /course/i,
                /degree/i,
                /study/i,
                /major/i
            ],
            fees_due: [
                /fees?\s*(?:due|amount|total|payable)/i,
                /tuition\s*(?:fees?|due|amount)/i,
                /school\s*fees?/i,
                /total\s*(?:fees?|amount)/i,
                /amount\s*(?:due|payable)/i
            ],
            fees_paid: [
                /fees?\s*(?:paid|payments?|received|settled)/i,
                /amount\s*paid/i,
                /payments?\s*(?:received|made)/i,
                /paid\s*amount/i
            ],
            balance: [
                /balance/i,
                /outstanding/i,
                /remaining/i,
                /due/i
            ],
            department: [
                /department/i,
                /dept/i,
                /faculty/i,
                /school/i
            ],
            academic_year: [
                /academic\s*(?:year|yr)/i,
                /year/i,
                /session/i,
                /intake/i
            ],
            semester: [
                /semester/i,
                /sem/i,
                /term/i,
                /trimester/i
            ],
            status: [
                /status/i,
                /state/i,
                /condition/i
            ]
        };

        // Known column name mappings
        this.knownColumns = {
            'studentnumber': 'student_number',
            'studentid': 'student_number',
            'regno': 'student_number',
            'regnumber': 'student_number',
            'admissionno': 'student_number',
            'admissionnumber': 'student_number',
            'firstname': 'first_name',
            'givenname': 'first_name',
            'forename': 'first_name',
            'surname': 'last_name',
            'familyname': 'last_name',
            'lastname': 'last_name',
            'middlename': 'middle_name',
            'fullname': 'full_name',
            'program': 'programme',
            'course': 'programme',
            'degree': 'programme',
            'tuition': 'fees_due',
            'tuitionfees': 'fees_due',
            'schoolfees': 'fees_due',
            'amountdue': 'fees_due',
            'totalamount': 'fees_due',
            'amountpaid': 'fees_paid',
            'payments': 'fees_paid',
            'paymentreceived': 'fees_paid',
            'outstanding': 'balance',
            'remaining': 'balance',
            'dept': 'department',
            'faculty': 'department',
            'academicyear': 'academic_year',
            'year': 'academic_year',
            'session': 'academic_year',
            'intake': 'academic_year',
            'sem': 'semester',
            'term': 'semester',
            'trimester': 'semester'
        };
    }

    /**
     * Smart column detection - finds the best match for a column header
     */
    detectColumn(header) {
        if (!header) return null;
        
        // Clean the header
        const clean = header.toString().trim();
        
        // Check known columns first
        const lower = clean.toLowerCase().replace(/[^a-z0-9]/g, '');
        if (this.knownColumns[lower]) {
            return this.knownColumns[lower];
        }

        // Try pattern matching
        for (const [field, patterns] of Object.entries(this.columnPatterns)) {
            for (const pattern of patterns) {
                if (pattern.test(clean)) {
                    return field;
                }
            }
        }

        // Try partial matching
        for (const [field, patterns] of Object.entries(this.columnPatterns)) {
            for (const pattern of patterns) {
                const patternStr = pattern.toString().replace(/[\/^$]/g, '').toLowerCase();
                if (clean.toLowerCase().includes(patternStr) || patternStr.includes(clean.toLowerCase())) {
                    return field;
                }
            }
        }

        // If it contains 'name' but not matched above
        if (/name/i.test(clean)) {
            if (/full/i.test(clean)) return 'full_name';
            if (/first|given|fore/i.test(clean)) return 'first_name';
            if (/last|sur|family/i.test(clean)) return 'last_name';
            if (/middle/i.test(clean)) return 'middle_name';
            return 'full_name';
        }

        return null;
    }

    /**
     * Parse and map Excel data intelligently
     */
    parseExcelData(jsonData) {
        if (!jsonData || jsonData.length === 0) {
            return { data: [], mapping: {}, errors: ['No data found'] };
        }

        // Detect column mapping
        const headers = Object.keys(jsonData[0]);
        const mapping = {};
        const unmapped = [];
        const mappingSuggestions = {};

        for (const header of headers) {
            const detected = this.detectColumn(header);
            if (detected) {
                mapping[header] = detected;
                mappingSuggestions[header] = detected;
            } else {
                unmapped.push(header);
                mappingSuggestions[header] = null;
            }
        }

        // Map data
        const mappedData = jsonData.map((row, index) => {
            const mappedRow = {
                _original_index: index,
                _row_data: row
            };

            for (const [header, field] of Object.entries(mapping)) {
                const value = row[header];
                if (value !== undefined && value !== null && value !== '') {
                    mappedRow[field] = value;
                }
            }

            // Try to extract name from full_name if available
            if (mappedRow.full_name && (!mappedRow.first_name || !mappedRow.last_name)) {
                const parts = mappedRow.full_name.toString().trim().split(/\s+/);
                if (parts.length >= 2) {
                    if (!mappedRow.first_name) mappedRow.first_name = parts[0];
                    if (!mappedRow.last_name) mappedRow.last_name = parts.slice(1).join(' ');
                } else if (!mappedRow.first_name) {
                    mappedRow.first_name = mappedRow.full_name;
                }
            }

            // Ensure required fields
            if (!mappedRow.student_number) {
                mappedRow.student_number = `S${String(index + 1).padStart(4, '0')}`;
            }

            // Parse numbers
            if (mappedRow.fees_due) {
                mappedRow.fees_due = parseFloat(mappedRow.fees_due) || 0;
            } else {
                mappedRow.fees_due = 0;
            }

            if (mappedRow.fees_paid) {
                mappedRow.fees_paid = parseFloat(mappedRow.fees_paid) || 0;
            } else {
                mappedRow.fees_paid = 0;
            }

            // Calculate balance
            mappedRow.balance = mappedRow.fees_due - mappedRow.fees_paid;
            mappedRow.status = mappedRow.balance <= 0 ? 'PAID' : 'PENDING';

            return mappedRow;
        });

        return {
            data: mappedData,
            mapping: mapping,
            unmapped: unmapped,
            mappingSuggestions: mappingSuggestions,
            errors: []
        };
    }

    /**
     * Generate mapping suggestions for user review
     */
    generateMappingSuggestions(headers) {
        const suggestions = {};
        for (const header of headers) {
            const detected = this.detectColumn(header);
            suggestions[header] = detected;
        }
        return suggestions;
    }

    /**
     * Validate the parsed data
     */
    validateData(data) {
        const errors = [];
        const warnings = [];

        for (const row of data) {
            // Check for required fields
            if (!row.first_name && !row.last_name) {
                errors.push(`Row ${row._original_index + 1}: Missing student name`);
            }
            if (row.fees_due < 0) {
                errors.push(`Row ${row._original_index + 1}: Fees due cannot be negative`);
            }
            if (row.fees_paid < 0) {
                errors.push(`Row ${row._original_index + 1}: Fees paid cannot be negative`);
            }
            if (row.fees_paid > row.fees_due) {
                warnings.push(`Row ${row._original_index + 1}: Fees paid (${row.fees_paid}) exceeds fees due (${row.fees_due})`);
            }
        }

        return { errors, warnings };
    }
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SmartExcelParser;
}
