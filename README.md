# Decentralized Public Park Tennis Court Reservation System

A comprehensive blockchain-based system for managing public tennis court operations, built on the Stacks blockchain using Clarity smart contracts.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of tennis court operations:

### 1. Court Booking Contract (`court-booking.clar`)
- Manages hourly tennis court reservations
- Handles booking fees and cancellations
- Tracks court availability and usage
- Prevents double-booking conflicts

### 2. Maintenance Scheduling Contract (`maintenance-scheduling.clar`)
- Coordinates court resurfacing and net repairs
- Schedules routine maintenance windows
- Tracks maintenance history and costs
- Manages contractor assignments

### 3. Lighting Control Contract (`lighting-control.clar`)
- Manages court illumination for evening play
- Controls automated lighting schedules
- Tracks energy usage and costs
- Handles manual lighting overrides

### 4. Tournament Organization Contract (`tournament-organization.clar`)
- Coordinates community tennis competitions
- Manages tournament registrations and brackets
- Handles prize distribution
- Schedules tournament matches

### 5. Weather Cancellation Contract (`weather-cancellation.clar`)
- Manages court closures during rain and storms
- Processes automatic refunds for weather cancellations
- Integrates with weather data feeds
- Maintains weather-related closure history

## Key Features

- **Decentralized Management**: No single point of failure
- **Transparent Operations**: All transactions recorded on blockchain
- **Automated Processes**: Smart contracts handle routine operations
- **Fair Access**: Equal opportunity booking system
- **Cost Tracking**: Transparent fee and maintenance cost tracking

## Contract Architecture

Each contract operates independently while maintaining data consistency:

- **Data Isolation**: Each contract manages its own state
- **Event Logging**: All major actions emit events for transparency
- **Error Handling**: Comprehensive error codes and validation
- **Access Control**: Role-based permissions for different operations

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation
\`\`\`bash
git clone <repository-url>
cd tennis-court-system
npm install
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Booking a Court
\`\`\`clarity
(contract-call? .court-booking book-court u1 u14 u1) ;; Court 1, 2PM, 1 hour
\`\`\`

### Scheduling Maintenance
\`\`\`clarity
(contract-call? .maintenance-scheduling schedule-maintenance u1 "net-repair" u1000000)
\`\`\`

### Controlling Lighting
\`\`\`clarity
(contract-call? .lighting-control set-lighting u1 true u18 u22) ;; Court 1, 6PM-10PM
\`\`\`

## Error Codes

Each contract uses standardized error codes:
- `u100-199`: Input validation errors
- `u200-299`: Permission errors
- `u300-399`: State conflicts
- `u400-499`: Resource not found
- `u500-599`: System errors

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
