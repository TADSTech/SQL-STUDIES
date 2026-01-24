const caseStudies = [
    {
        category: 'window_functions',
        title: 'Ranking Functions',
        description: 'ROW_NUMBER, RANK, and DENSE_RANK for leaderboards and deduplication',
        file: '01_ranking_functions.md'
    },
    {
        category: 'window_functions',
        title: 'LAG & LEAD',
        description: 'Month-over-month comparisons and trend analysis',
        file: '02_lag_lead.md'
    },
    {
        category: 'window_functions',
        title: 'Moving Averages',
        description: 'Rolling windows, running totals, and trend smoothing',
        file: '03_moving_averages.md'
    },
    {
        category: 'ctes',
        title: 'Multi-CTE Pipelines',
        description: 'Chained data transformations with named CTEs',
        file: '01_multi_cte_pipeline.md'
    },
    {
        category: 'ctes',
        title: 'Recursive Hierarchy',
        description: 'Org chart traversal and tree structures',
        file: '02_recursive_hierarchy.md'
    },
    {
        category: 'ctes',
        title: 'CTE Refactoring',
        description: 'Converting nested subqueries to clean CTEs',
        file: '03_cte_refactoring.md'
    },
    {
        category: 'analytics_metrics',
        title: 'Retention Analysis',
        description: 'Cohort-based user retention calculations',
        file: '01_retention_analysis.md'
    },
    {
        category: 'analytics_metrics',
        title: 'Churn Calculation',
        description: 'Customer and revenue churn rate metrics',
        file: '02_churn_calculation.md'
    },
    {
        category: 'analytics_metrics',
        title: 'Revenue Metrics',
        description: 'MRR, ARR, and customer lifetime value (LTV)',
        file: '03_revenue_metrics.md'
    },
    {
        category: 'optimization',
        title: 'Index-Aware Queries',
        description: 'Writing queries that leverage database indexes',
        file: '01_index_aware_queries.md'
    },
    {
        category: 'optimization',
        title: 'Query Refactoring',
        description: 'Systematic performance improvements',
        file: '02_query_refactoring.md'
    },
    {
        category: 'optimization',
        title: 'Avoiding Anti-Patterns',
        description: 'Common SQL mistakes and their fixes',
        file: '03_avoiding_antipatterns.md'
    },
    {
        category: 'joins',
        title: 'Conditional Aggregation',
        description: 'CASE expressions inside aggregate functions',
        file: '01_conditional_aggregation.md'
    },
    {
        category: 'joins',
        title: 'Complex Joins',
        description: 'Multi-table joins with cardinality handling',
        file: '02_complex_joins.md'
    },
    {
        category: 'joins',
        title: 'Self-Joins',
        description: 'Same-table comparisons and hierarchies',
        file: '03_self_joins.md'
    }
];

const categories = {
    all: 'All',
    window_functions: 'Window Functions',
    ctes: 'CTEs',
    analytics_metrics: 'Analytics',
    optimization: 'Optimization',
    joins: 'Joins'
};

let activeCategory = 'all';

function renderTabs() {
    const tabsContainer = document.getElementById('categoryTabs');
    tabsContainer.innerHTML = Object.entries(categories).map(([key, label]) => `
        <button class="category-tab ${activeCategory === key ? 'active' : ''}" 
                onclick="filterCategory('${key}')">
            ${label}
        </button>
    `).join('');
}

function renderStudies() {
    const grid = document.getElementById('studiesGrid');
    const filtered = activeCategory === 'all'
        ? caseStudies
        : caseStudies.filter(s => s.category === activeCategory);

    grid.innerHTML = filtered.map(study => `
        <a href="case_studies/${study.category}/${study.file}" class="study-card">
            <div class="study-card-header">
                <h3>${study.title}</h3>
                <span class="study-card-category">${categories[study.category]}</span>
            </div>
            <p>${study.description}</p>
        </a>
    `).join('');
}

function filterCategory(category) {
    activeCategory = category;
    renderTabs();
    renderStudies();
}

function copyCode(btn) {
    const code = btn.closest('.code-block').querySelector('code').textContent;
    navigator.clipboard.writeText(code).then(() => {
        const originalText = btn.textContent;
        btn.textContent = 'Copied!';
        setTimeout(() => btn.textContent = originalText, 2000);
    });
}

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    });
});

document.addEventListener('DOMContentLoaded', () => {
    renderTabs();
    renderStudies();
});
