# Sextant Tutorial 3: Adding Fertility

## Overview

In this tutorial, you'll learn how to add fertility to your demographic model. We'll build on the aging and mortality model from Tutorial 2, adding births to create a more complete population simulation.

## What You'll Learn

By the end of this tutorial, you'll be able to:
- Add a fertility model to your simulation
- Create new individuals (births) with appropriate characteristics
- Track population growth

## Prerequisites

- Completion of Tutorial 2 (or equivalent knowledge)
- The `population.csv` file from Tutorial 1
- A text editor

---

## Part 1: What We're Going to Build

So far we have:
- ✅ **Aging**: Everyone gets older each year
- ✅ **Mortality**: Some people die based on their age

Now we'll add:
- **Fertility**: Women of childbearing age can give birth

### What We Want to Do

**In plain English:** "Each year, for every woman aged 15-49 who is alive, there is a 5% chance she gives birth. If she gives birth, we add a new person to the population. The new baby inherits the mother's area, is randomly male or female, and is marked as alive."

### Why This Matters

Adding fertility completes the demographic cycle:
- **Births** add people to the population
- **Aging** moves people through the life course
- **Deaths** remove people from the population

With all three models, we can simulate realistic population dynamics.

---

## Part 2: Understanding Lua Table Operations

Before we write our fertility model, let's understand how to work with tables (lists) in Lua.

### Adding Items to a Table

In Lua, `table.insert()` adds a new item to the end of a list:

```lua
-- Create a list
local newborns = {}

-- Add a new person to the list
table.insert(newborns, {
  person_id = 11,
  age = 0,
  sex = "F",
  area_id = 1,
  alive = true
})
```

### Creating a New Person

A person is just a table with properties:

```lua
local baby = {
  person_id = 11,
  age = 0,
  sex = "F",
  area_id = 1,
  alive = true
}
```

### Finding the Maximum ID

To create new unique IDs, we need to find the highest existing ID:

```lua
local max_id = 0
for _, person in ipairs(population) do
  if person.person_id > max_id then
    max_id = person.person_id
  end
end
```

Then the next ID is `max_id + 1`.

---

## Part 3: The Fertility Model in Lua

### The Complete Fertility Model

Here's the Lua script for our fertility model:

```lua
function transition(population, params)
  -- Get fertility rate from parameters
  local fertility_rate = params.fertility_rate or 0.05
  
  -- Create a list for newborns
  local newborns = {}
  
  -- Find the maximum ID
  local max_id = 0
  for _, person in ipairs(population) do
    if person.person_id ~= nil and person.person_id > max_id then
      max_id = person.person_id
    end
  end
  
  -- Process each person
  for _, person in ipairs(population) do
    -- Check if this person is a fertile woman
    if person.alive == true and person.sex == "F" then
      local age = person.age
      if age >= 15 and age < 50 then
        -- Roll the dice for fertility
        if math.random() < fertility_rate then
          -- Create a newborn
          max_id = max_id + 1
          local baby = {
            person_id = max_id,
            age = 0,
            sex = math.random() < 0.5 and "F" or "M",
            area_id = person.area_id,
            alive = true
          }
          table.insert(newborns, baby)
        end
      end
    end
  end
  
  -- Add newborns to population
  for _, baby in ipairs(newborns) do
    table.insert(population, baby)
  end
  
  return population
end
```

### Breaking It Down Piece by Piece

**First, in plain English:** "Go through every woman who is alive and aged 15-49. For each one, flip a coin. If it comes up heads (5% chance), create a new baby. The baby gets a new ID, age 0, a random sex (50:50), and lives in the same area as the mother. The baby is alive."

**Now let's break down each part:**

| Part | What it does | In plain English |
|------|--------------|------------------|
| `local fertility_rate = params.fertility_rate or 0.05` | Get rate | "Use the rate from the config, or 5% if not specified" |
| `local newborns = {}` | Create list | "Create an empty list for babies born this year" |
| `for _, person in ipairs(population) do` | Loop through people | "For each person in the population..." |
| `if person.alive == true and person.sex == "F" then` | Check woman | "...if they are a woman and alive..." |
| `if age >= 15 and age < 50 then` | Check age | "...and they're of childbearing age (15-49)..." |
| `if math.random() < fertility_rate then` | Roll dice | "...roll a random number..." |
| `max_id = max_id + 1` | New ID | "...if it's less than the fertility rate, create a new ID" |
| `local baby = { ... }` | Create baby | "...create a new baby with properties" |
| `table.insert(newborns, baby)` | Add to list | "...add the baby to the list of newborns" |
| `table.insert(population, baby)` | Add to population | "...add the baby to the population" |

---

## Part 4: Adding Fertility to Our Configuration

Here's our complete configuration with aging, mortality, and fertility:

```yaml
# config_aging_mortality_fertility.yaml
# Complete demographic model with aging, mortality, and fertility

simulation:
  iterations: 10
  population_file: "population.csv"
  output_file: "population_complete.csv"
  random_seed: 42
  verbose: true
  id_column: "person_id"
  streaming_mode: false

models:
  # Model 1: Age increment (runs first)
  - name: "age_increment"
    type: "lua_model"
    priority: 1
    enabled: true
    description: "Increment everyone's age by 1 year"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              person.age = person.age + 1
            end
          end
          return population
        end

  # Model 2: Mortality (runs second)
  - name: "mortality"
    type: "lua_model"
    priority: 2
    enabled: true
    description: "Age-specific mortality: 0.1% for under 30, 5% for 30+"
    parameters:
      script: |
        function transition(population, params)
          for _, person in ipairs(population) do
            if person.alive == true then
              local age = person.age
              local prob = 0
              
              if age < 30 then
                prob = 0.001
              else
                prob = 0.05
              end
              
              if math.random() < prob then
                person.alive = false
              end
            end
          end
          return population
        end

  # Model 3: Fertility (runs third)
  - name: "fertility"
    type: "lua_model"
    priority: 3
    enabled: true
    description: "Fertility: 5% chance for women aged 15-49 to give birth"
    parameters:
      fertility_rate: 0.05
      script: |
        function transition(population, params)
          local fertility_rate = params.fertility_rate
          local newborns = {}
          
          local max_id = 0
          for _, person in ipairs(population) do
            if person.person_id ~= nil and person.person_id > max_id then
              max_id = person.person_id
            end
          end
          
          for _, person in ipairs(population) do
            if person.alive == true and person.sex == "F" then
              local age = person.age
              if age >= 15 and age < 50 then
                if math.random() < fertility_rate then
                  max_id = max_id + 1
                  local baby = {
                    person_id = max_id,
                    age = 0,
                    sex = math.random() < 0.5 and "F" or "M",
                    area_id = person.area_id,
                    alive = true
                  }
                  table.insert(newborns, baby)
                end
              end
            end
          end
          
          for _, baby in ipairs(newborns) do
            table.insert(population, baby)
          end
          
          return population
        end
```

---

## Part 5: Running the Complete Model

Save the configuration as `config_aging_mortality_fertility.yaml` and run it:

```bash
./sextant config_aging_mortality_fertility.yaml
```

### Expected Output

```
2024/01/15 10:00:00 ═══ Sextant: Microsimulation Engine ═══
2024/01/15 10:00:00 Iterations: 10
2024/01/15 10:00:00 Population file: population.csv
2024/01/15 10:00:00 ID column: person_id
2024/01/15 10:00:00 Mode: BULK (load all into memory)
2024/01/15 10:00:00 Models loaded: 3
2024/01/15 10:00:00 Loaded 10 individuals with 4 columns
2024/01/15 10:00:00 Enabled models: 3
2024/01/15 10:00:00   - age_increment (priority: 1)
2024/01/15 10:00:00   - mortality (priority: 2)
2024/01/15 10:00:00   - fertility (priority: 3)

2024/01/15 10:00:00 ═══ Iteration 1/10 ═══
2024/01/15 10:00:00   ▶ age_increment
2024/01/15 10:00:00   ▶ mortality
2024/01/15 10:00:00   ▶ fertility

...

2024/01/15 10:00:00 ═══ Simulation Complete ═══
2024/01/15 10:00:00 Results saved to population_complete.csv
```

---

## Part 6: Why Model Order Matters

The order of models is crucial. Here's why we run them in this specific order:

### Priority 1: Aging First

```yaml
priority: 1  # Runs first
```

**Why?** Women need to be the correct age for fertility. A woman who is 14 should not give birth, but if she turns 15 this year, she should be eligible.

### Priority 2: Mortality Second

```yaml
priority: 2  # Runs second
```

**Why?** Dead women shouldn't give birth. We need to remove people who die before checking fertility.

### Priority 3: Fertility Last

```yaml
priority: 3  # Runs last
```

**Why?** Newborns shouldn't be aged or killed in the same year they're born.

### Visualizing the Order

```
Start of Year
    ↓
1. AGE everyone (including women who turn 15)
    ↓
2. MORTALITY (dead people don't give birth)
    ↓
3. FERTILITY (women give birth to babies who are age 0)
    ↓
End of Year
```

---

## Part 7: What You've Accomplished

Congratulations! You now have a complete demographic microsimulation model with:

1. ✅ **Aging**: Everyone gets older each year
2. ✅ **Mortality**: Age-specific death probabilities
3. ✅ **Fertility**: Women of childbearing age can give birth
4. ✅ **Population Growth**: Births and deaths change population size

### The Full Demographic Cycle

```
    ┌─────────────────────────────────────┐
    │                                     │
    │          POPULATION                 │
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   1. AGE (everyone gets older)      │
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   2. MORTALITY (some people die)    │
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   3. FERTILITY (some women give birth)
    │                                     │
    └─────────────┬───────────────────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │                                     │
    │   Next year: repeat!                │
    │                                     │
    └─────────────────────────────────────┘
```

---

## Summary of Lua Concepts Learned

| Concept | What it does | Example |
|---------|--------------|---------|
| `table.insert()` | Add to list | `table.insert(list, item)` |
| `math.random()` | Random number | `math.random()` |
| `and` / `or` | Logical operators | `if person.alive and person.sex == "F"` |
| `{}` | Create table | `{ name = "John", age = 25 }` |
| `for` loop | Iterate | `for _, person in ipairs(population) do` |
| `if-elseif-else` | Conditions | `if age < 18 then ... end` |
| `or` | Default value | `rate = params.rate or 0.05` |

---

## Summary

In this tutorial, you've learned:

1. **Fertility Model**: How to add births to your simulation
2. **Creating New Individuals**: How to create new people with unique IDs
3. **Model Priority**: Why order matters (age → mortality → fertility)
4. **Population Growth**: How births and deaths change population size

---

## Next Steps

You've now completed the three core tutorials and have a working demographic microsimulation model!

**What you can do next:**
- Experiment with different fertility and mortality rates
- Add new columns to your CSV (e.g., education, income)
- Create your own models by modifying the Lua scripts
- Try running with larger populations

---

**Well done for completing Tutorial 3!** You now have a complete demographic simulation with aging, mortality, and fertility. You understand the full demographic cycle and can build your own models!
```