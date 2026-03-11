package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strings"
)

func main() {
	// Map to keep track of seen bread names
	seen := make(map[string]bool)

	// Regex to find the `name: '...'` field
	nameRegex := regexp.MustCompile(`(?m)^\s*name:\s*'([^']+)'`)

	scanner := bufio.NewScanner(os.Stdin)
	var output []string
	var buffer []string
	inBread := false
	currentName := ""

	for scanner.Scan() {
		line := scanner.Text()

		if strings.Contains(line, "Bread(") {
			inBread = true
			buffer = []string{line}
			currentName = ""
			continue
		}

		if inBread {
			buffer = append(buffer, line)

			// Check for name while inside Bread()
			if currentName == "" {
				if match := nameRegex.FindStringSubmatch(line); match != nil {
					currentName = match[1]
				}
			}

			// Detect end of Bread object
			if strings.Contains(line, "),") || strings.Contains(line, ")") {
				inBread = false
				if currentName != "" && !seen[currentName] {
					seen[currentName] = true
					output = append(output, buffer...)
				}
			}
			continue
		}

		// Copy other lines (e.g., opening list declaration, etc.)
		output = append(output, line)
	}

	// Output cleaned Dart code
	for _, line := range output {
		fmt.Println(line)
	}
}
