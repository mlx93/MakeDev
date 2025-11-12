#!/usr/bin/env tsx
/**
 * Smart Seed Generator
 * 
 * Reads Prisma schema dynamically and generates realistic test data using Faker.js.
 * Works with any Prisma schema, not just User/Task models.
 * 
 * Usage: tsx scripts/seed-database.ts [project-root]
 */

import { readFileSync, existsSync } from 'fs'
import { join, dirname, resolve } from 'path'
import { fileURLToPath } from 'url'
import { parse } from 'yaml'
import { faker } from '@faker-js/faker'
import { PrismaClient } from '@prisma/client'

// Faker v8+ uses English (US) by default, no need to set locale

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

// Detect project root (current directory or parent if in subdirectory)
function findProjectRoot(): string {
  let currentDir = process.cwd()
  const maxDepth = 5
  
  for (let i = 0; i < maxDepth; i++) {
    if (existsSync(join(currentDir, 'config.yaml')) || existsSync(join(currentDir, 'backend', 'prisma', 'schema.prisma'))) {
      return currentDir
    }
    const parent = dirname(currentDir)
    if (parent === currentDir) break // Reached filesystem root
    currentDir = parent
  }
  
  return process.cwd() // Fallback to current directory
}

// Parse command line arguments
const projectRoot = process.argv[2] || findProjectRoot()
const configPath = join(projectRoot, 'config.yaml')
const backendPath = join(projectRoot, 'backend')
const defaultSchemaPath = join(backendPath, 'prisma', 'schema.prisma')

// Read config.yaml
let config: any = {}
if (existsSync(configPath)) {
  try {
    const configContent = readFileSync(configPath, 'utf-8')
    config = parse(configContent)
  } catch (error) {
    console.error(`❌ Failed to read config.yaml: ${error}`)
    process.exit(1)
  }
} else {
  console.warn(`⚠️  config.yaml not found at ${configPath}, using defaults`)
}

// Get seed configuration
const seedConfig = config.seed || {}
const userCount = seedConfig.users || 30
const tasksPerUser = seedConfig.tasks_per_user || '5-10'

// Get schema path from config or use default
const schemaPath = config.services?.database?.schema_path 
  ? resolve(projectRoot, config.services.database.schema_path)
  : defaultSchemaPath

if (!existsSync(schemaPath)) {
  console.error(`❌ Prisma schema not found at ${schemaPath}`)
  console.error(`   Please ensure the schema file exists or set services.database.schema_path in config.yaml`)
  process.exit(1)
}

// Read and parse Prisma schema
const schemaContent = readFileSync(schemaPath, 'utf-8')
const models = parsePrismaSchema(schemaContent)

if (models.length === 0) {
  console.error(`❌ No models found in Prisma schema`)
  process.exit(1)
}

console.log(`📋 Found ${models.length} model(s) in schema: ${models.map(m => m.name).join(', ')}`)

// Initialize Prisma client
// Prisma client must be generated in the backend directory
// We'll use the DATABASE_URL from environment or default
const databaseUrl = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/appdb'

// Change to backend directory to use Prisma client
// Note: Prisma client is generated per-project in backend/node_modules
const originalCwd = process.cwd()
if (existsSync(backendPath)) {
  process.chdir(backendPath)
}

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: databaseUrl
    }
  }
})

// Field type to Faker.js mapping
const fieldToFaker: Record<string, (field: Field) => any> = {
  email: () => faker.internet.email(),
  name: () => faker.person.fullName(),
  firstName: () => faker.person.firstName(),
  lastName: () => faker.person.lastName(),
  title: () => {
    // Generate realistic task titles
    const actions = ['Review', 'Update', 'Fix', 'Implement', 'Test', 'Deploy', 'Document', 'Optimize', 'Refactor', 'Create']
    const subjects = ['API endpoint', 'database schema', 'user interface', 'authentication flow', 'email template', 'report generation', 'payment integration', 'search functionality', 'mobile layout', 'error handling']
    return `${faker.helpers.arrayElement(actions)} ${faker.helpers.arrayElement(subjects)}`
  },
  description: () => faker.hacker.phrase(),
  content: () => faker.hacker.phrase(),
  createdAt: () => faker.date.recent({ days: 30 }),
  updatedAt: () => faker.date.recent({ days: 7 }),
  password: () => '$2a$10$' + faker.string.alphanumeric(53), // bcrypt hash placeholder
  url: () => faker.internet.url(),
  image: () => faker.image.url(),
  phone: () => faker.phone.number(),
  address: () => faker.location.streetAddress(),
  city: () => faker.location.city(),
  country: () => faker.location.country(),
  zipCode: () => faker.location.zipCode(),
  company: () => faker.company.name(),
  jobTitle: () => faker.person.jobTitle(),
  bio: () => faker.person.bio(),
  completed: () => faker.datatype.boolean(),
  status: (field: Field) => {
    // Try to get enum values from field type
    if (field.type.includes('Status')) {
      return faker.helpers.arrayElement(['TODO', 'IN_PROGRESS', 'DONE', 'ARCHIVED'])
    }
    return faker.helpers.arrayElement(['active', 'inactive', 'pending'])
  },
  priority: () => faker.helpers.arrayElement(['LOW', 'MEDIUM', 'HIGH', 'URGENT']),
  dueDate: () => faker.date.future(),
}

// Generate value for a field
function generateFieldValue(field: Field, modelName: string, existingIds: Record<string, number[]>): any {
  // Skip auto-generated fields
  if (field.isId && field.hasDefault) return undefined
  if (field.name === 'id' && field.hasDefault) return undefined
  if (field.name === 'createdAt' && field.hasDefault) return undefined
  if (field.name === 'updatedAt' && field.hasDefault) return undefined

  // Handle foreign keys
  if (field.isForeignKey) {
    const referencedModel = field.type.replace('Int', '').replace('String', '')
    const ids = existingIds[referencedModel] || []
    if (ids.length === 0) {
      throw new Error(`No ${referencedModel} records found for foreign key ${field.name}`)
    }
    return faker.helpers.arrayElement(ids)
  }

  // Handle optional fields (70% filled, 30% null)
  if (field.isOptional && Math.random() > 0.7) {
    return null
  }

  // Map field name to Faker generator
  const fieldNameLower = field.name.toLowerCase()
  for (const [key, generator] of Object.entries(fieldToFaker)) {
    if (fieldNameLower.includes(key)) {
      return generator(field)
    }
  }

  // Default based on type
  switch (field.type) {
    case 'String':
      return faker.company.catchPhrase()
    case 'Int':
      return faker.number.int({ min: 1, max: 1000 })
    case 'Float':
      return faker.number.float({ min: 0, max: 100, fractionDigits: 2 })
    case 'Boolean':
      return faker.datatype.boolean()
    case 'DateTime':
      return faker.date.recent({ days: 30 })
    case 'Json':
      return { data: faker.company.catchPhrase() }
    default:
      // Try to detect enum
      if (field.type.match(/^[A-Z][a-zA-Z]*$/)) {
        // Assume it's an enum, return a placeholder
        return 'TODO_ENUM_VALUE'
      }
      return null
  }
}

// Parse Prisma schema to extract models
interface Field {
  name: string
  type: string
  isOptional: boolean
  isId: boolean
  hasDefault: boolean
  isForeignKey: boolean
  isUnique: boolean
}

interface Model {
  name: string
  fields: Field[]
}

function parsePrismaSchema(schema: string): Model[] {
  const models: Model[] = []
  const modelRegex = /model\s+(\w+)\s*\{([^}]+)\}/g
  let match

  while ((match = modelRegex.exec(schema)) !== null) {
    const modelName = match[1]
    const modelBody = match[2]
    const fields: Field[] = []

    const fieldRegex = /(\w+)\s+(\w+[?\[\]]*)(\s+@[^\n]+)?/g
    let fieldMatch

    while ((fieldMatch = fieldRegex.exec(modelBody)) !== null) {
      const fieldName = fieldMatch[1]
      const fieldTypeRaw = fieldMatch[2]
      const fieldType = fieldTypeRaw.replace(/[?\[\]]/g, '')
      const attributes = fieldMatch[3] || ''

      const isOptional = fieldTypeRaw.includes('?')
      const isId = attributes.includes('@id')
      const hasDefault = attributes.includes('@default')
      const isUnique = attributes.includes('@unique')
      // A field is a relation if it has @relation attribute, has array type (Task[]), 
      // or is a non-scalar type (starts with uppercase and isn't a known Prisma type)
      const isArray = fieldTypeRaw.includes('[')
      const isRelationAttribute = attributes.includes('@relation') || attributes.includes('references')
      const isNonScalarType = /^[A-Z]/.test(fieldType) && 
        !['String', 'Int', 'Float', 'Boolean', 'DateTime', 'Json', 'Decimal', 'BigInt', 'Bytes'].includes(fieldType)
      const isForeignKey = isArray || isRelationAttribute || (isNonScalarType && !attributes.includes('@default'))

      fields.push({
        name: fieldName,
        type: fieldType,
        isOptional,
        isId,
        hasDefault,
        isForeignKey,
        isUnique
      })
    }

    models.push({ name: modelName, fields })
  }

  return models
}

// Check if a table exists in the database
async function tableExists(tableName: string): Promise<boolean> {
  try {
    // Use raw SQL to check if table exists in public schema
    // Use Prisma.sql for safe parameterized queries
    const result = await prisma.$queryRaw<Array<{ exists: boolean }>>`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = ${tableName.toLowerCase()}
      ) as exists
    `
    return result[0]?.exists || false
  } catch (error) {
    // If query fails, assume table doesn't exist
    // This handles cases where the database isn't ready or tables haven't been created
    return false
  }
}

// Generate seed data
async function generateSeedData() {
  const startTime = Date.now()
  const existingIds: Record<string, number[]> = {}
  const stats: Record<string, number> = {}

  try {
    // Connect to database
    await prisma.$connect()
    console.log('✅ Connected to database')

    // Check if public.user table exists - if not, skip seeding (hello world apps don't have tables)
    const userTableExists = await tableExists('user')
    if (!userTableExists) {
      console.log('\n⏭️  No database tables found (public.user does not exist)')
      console.log('   Skipping seed - this appears to be a hello world app without database tables')
      console.log('   Seed is only needed for apps with Prisma models and database tables')
      return
    }

    // Find User model (if exists) and generate users first
    const userModel = models.find(m => m.name.toLowerCase() === 'user')
    let demoUserEmail = ''
    let demoUserPassword = ''
    
    if (userModel) {
      console.log(`\n👥 Generating ${userCount} users...`)
      
      // Check if users already exist (for idempotency)
      const existingUsers = await (prisma as any)[userModel.name].findMany({
        select: { id: true, email: true }
      })
      
      // Check if demo user exists
      const demoUser = existingUsers.find((u: any) => u.email === 'demo@example.com')
      
      if (existingUsers.length > 0) {
        console.log(`   ⚠️  ${existingUsers.length} users already exist, skipping user generation`)
        existingIds[userModel.name] = existingUsers.map((u: any) => u.id)
        if (demoUser) {
          demoUserEmail = 'demo@example.com'
          demoUserPassword = 'demo123'
        }
      } else {
        const users = []
        
        // First, create a demo user with known credentials
        const demoUserData: any = {}
        demoUserEmail = 'demo@example.com'
        demoUserPassword = 'demo123'
        
        for (const field of userModel.fields) {
          // Skip auto-generated IDs and relation fields
          if (field.isId && field.hasDefault) continue
          if (field.isForeignKey) continue
          
          // Set specific values for demo user
          if (field.name === 'email') {
            demoUserData[field.name] = demoUserEmail
          } else if (field.name === 'name') {
            demoUserData[field.name] = 'Demo User'
          } else if (field.name === 'password') {
            // Pre-computed bcrypt hash of 'demo123' (generated with bcrypt.hash('demo123', 10))
            demoUserData[field.name] = '$2b$10$O4KPD/hkO0k3Stoopw6twOm4Fgs.Fb2Zrb8EAAFiWo8KMaj.tEhJS'
          } else {
            const value = generateFieldValue(field, userModel.name, existingIds)
            if (value !== undefined) {
              demoUserData[field.name] = value
            }
          }
        }
        users.push(demoUserData)
        
        // Generate remaining random users
        for (let i = 1; i < userCount; i++) {
          const userData: any = {}
          for (const field of userModel.fields) {
            // Skip auto-generated IDs and relation fields
            if (field.isId && field.hasDefault) continue
            if (field.isForeignKey) continue
            const value = generateFieldValue(field, userModel.name, existingIds)
            if (value !== undefined) {
              userData[field.name] = value
            }
          }
          users.push(userData)
        }

        // Insert users in batches
        const batchSize = 10
        for (let i = 0; i < users.length; i += batchSize) {
          const batch = users.slice(i, i + batchSize)
          await Promise.all(
            batch.map(userData => (prisma as any)[userModel.name].create({ data: userData }))
          )
        }

        // Get created user IDs
        const createdUsers = await (prisma as any)[userModel.name].findMany({
          select: { id: true }
        })
        existingIds[userModel.name] = createdUsers.map((u: any) => u.id)
        stats[userModel.name] = createdUsers.length
        console.log(`   ✅ Created ${createdUsers.length} users`)
      }
    }

    // Find Task model (if exists) and generate tasks
    const taskModel = models.find(m => m.name.toLowerCase() === 'task')
    if (taskModel && userModel && existingIds[userModel.name]?.length > 0) {
      console.log(`\n📝 Generating tasks...`)
      
      // Parse tasks_per_user (can be "5-10" or a number)
      let minTasks = 5
      let maxTasks = 10
      if (typeof tasksPerUser === 'string' && tasksPerUser.includes('-')) {
        const [min, max] = tasksPerUser.split('-').map(Number)
        minTasks = min
        maxTasks = max
      } else {
        const fixed = Number(tasksPerUser) || 5
        minTasks = fixed
        maxTasks = fixed
      }

      const userIds = existingIds[userModel.name]
      const tasks = []

      for (const userId of userIds) {
        const taskCount = faker.number.int({ min: minTasks, max: maxTasks })
        for (let i = 0; i < taskCount; i++) {
          const taskData: any = {}
          for (const field of taskModel.fields) {
            // Skip auto-generated IDs
            if (field.isId && field.hasDefault) continue
            
            // Skip relation object fields (user User @relation(...))
            // These are handled by Prisma via foreign key fields
            if (field.isForeignKey && field.type !== 'Int' && field.type !== 'String') continue
            
            // Set scalar foreign key fields (userId Int)
            if (field.name.toLowerCase().includes('user') && field.name.toLowerCase().includes('id')) {
              taskData[field.name] = userId
            } else {
              const value = generateFieldValue(field, taskModel.name, existingIds)
              if (value !== undefined) {
                taskData[field.name] = value
              }
            }
          }
          tasks.push(taskData)
        }
      }

      // Insert tasks in batches
      const batchSize = 50
      let createdTasks = 0
      for (let i = 0; i < tasks.length; i += batchSize) {
        const batch = tasks.slice(i, i + batchSize)
        await Promise.all(
          batch.map(taskData => (prisma as any)[taskModel.name].create({ data: taskData }))
        )
        createdTasks += batch.length
        process.stdout.write(`\r   ⏳ Created ${createdTasks}/${tasks.length} tasks...`)
      }
      console.log(`\n   ✅ Created ${createdTasks} tasks`)
      stats[taskModel.name] = createdTasks
    }

    // Generate data for other models (if any)
    const otherModels = models.filter(
      m => m.name.toLowerCase() !== 'user' && m.name.toLowerCase() !== 'task'
    )

    if (otherModels.length > 0) {
      console.log(`\n📦 Generating data for other models...`)
      for (const model of otherModels) {
        // Skip if no way to generate meaningful data
        if (model.fields.length === 0) continue

        console.log(`   Generating ${model.name}...`)
        // Generate a small number of records for other models
        const recordCount = 10
        const records = []
        for (let i = 0; i < recordCount; i++) {
          const recordData: any = {}
          for (const field of model.fields) {
            // Skip auto-generated IDs and relation fields
            if (field.isId && field.hasDefault) continue
            if (field.isForeignKey) continue
            const value = generateFieldValue(field, model.name, existingIds)
            if (value !== undefined) {
              recordData[field.name] = value
            }
          }
          records.push(recordData)
        }

        const batchSize = 10
        for (let i = 0; i < records.length; i += batchSize) {
          const batch = records.slice(i, i + batchSize)
          await Promise.all(
            batch.map(recordData => (prisma as any)[model.name].create({ data: recordData }))
          )
        }
        stats[model.name] = records.length
        console.log(`   ✅ Created ${records.length} ${model.name} records`)
      }
    }

    const duration = ((Date.now() - startTime) / 1000).toFixed(2)
    console.log(`\n✨ Seed data generation complete!`)
    console.log(`\n📊 Summary:`)
    for (const [model, count] of Object.entries(stats)) {
      console.log(`   ${model}: ${count} records`)
    }
    
    // Display demo user credentials if they exist
    if (demoUserEmail && demoUserPassword) {
      console.log('\n🔑 Demo User Credentials:')
      console.log(`   Email:    ${demoUserEmail}`)
      console.log(`   Password: ${demoUserPassword}`)
      console.log('\n   Use these credentials to log in at http://localhost:3000')
    }
    
    console.log(`\n⏱️  Execution time: ${duration}s`)

  } catch (error) {
    console.error(`\n❌ Error generating seed data:`, error)
    throw error
  } finally {
    await prisma.$disconnect()
    // Restore original working directory
    process.chdir(originalCwd)
  }
}

// Run seed generation
generateSeedData()
  .then(() => {
    process.exit(0)
  })
  .catch((error) => {
    console.error(`\n❌ Seed generation failed:`, error)
    process.exit(1)
  })

