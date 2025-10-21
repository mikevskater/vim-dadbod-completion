" ==============================================================================
" vim-dadbod-ui IntelliSense Integration Module
" ==============================================================================
" This module provides enhanced completions by leveraging vim-dadbod-ui's
" Phase 2 IntelliSense features including:
" - Context-aware completions
" - Table alias resolution
" - External database support
" - Schema-qualified name completion
" - Enriched metadata (data types, nullability, etc.)
" ==============================================================================

let s:mark = get(g:, 'vim_dadbod_completion_mark', '[DB]')

" Check if vim-dadbod-ui IntelliSense is available
" @return 1 if available and enabled, 0 otherwise
function! vim_dadbod_completion#dbui#is_available() abort
  return exists('*db_ui#completion#is_available') &&
        \ db_ui#completion#is_available()
endfunction

" Get enhanced completions using vim-dadbod-ui IntelliSense
" @param bufnr - Buffer number
" @param base - Completion base text
" @param line - Current line text
" @param col - Current column
" @return List of completion items
function! vim_dadbod_completion#dbui#get_completions(bufnr, base, line, col) abort
  if !vim_dadbod_completion#dbui#is_available()
    return []
  endif

  let db_key_name = getbufvar(a:bufnr, 'dbui_db_key_name')
  if empty(db_key_name)
    return []
  endif

  " Get cursor context using Phase 2 parser
  let context = db_ui#completion#get_cursor_context(a:bufnr, a:line, a:col)

  " Get completions based on context type
  if context.type ==# 'column'
    return s:get_column_completions(db_key_name, context, a:base)
  elseif context.type ==# 'table'
    return s:get_table_completions(db_key_name, context, a:base)
  elseif context.type ==# 'schema'
    return s:get_schema_completions(db_key_name, context, a:base)
  elseif context.type ==# 'database'
    return s:get_database_completions(db_key_name, context, a:base)
  elseif context.type ==# 'procedure'
    return s:get_procedure_completions(db_key_name, context, a:base)
  elseif context.type ==# 'function'
    return s:get_function_completions(db_key_name, context, a:base)
  elseif context.type ==# 'parameter'
    return s:get_parameter_completions(db_key_name, context, a:base)
  elseif context.type ==# 'column_or_function'
    " Mix of columns and functions
    let items = []
    call extend(items, s:get_column_completions(db_key_name, context, a:base))
    call extend(items, s:get_function_completions(db_key_name, context, a:base))
    return items
  elseif context.type ==# 'all_objects'
    return s:get_all_object_completions(db_key_name, context, a:base)
  else
    return []
  endif
endfunction

" ==============================================================================
" Completion Type Handlers
" ==============================================================================

" Get column completions
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_column_completions(db_key_name, context, base) abort
  let table_name = ''

  " Resolve table name from alias or direct reference
  if !empty(a:context.alias) && has_key(a:context.aliases, a:context.alias)
    let alias_info = a:context.aliases[a:context.alias]
    let table_name = alias_info.table

    " Check if it's an external database reference
    if !empty(alias_info.database)
      return s:get_external_column_completions(
            \ a:db_key_name,
            \ alias_info.database,
            \ table_name,
            \ a:base
            \ )
    endif
  elseif !empty(a:context.table)
    let table_name = a:context.table

    " Check for external database
    if !empty(a:context.database)
      return s:get_external_column_completions(
            \ a:db_key_name,
            \ a:context.database,
            \ table_name,
            \ a:base
            \ )
    endif
  endif

  if empty(table_name)
    return []
  endif

  " Get columns from vim-dadbod-ui cache
  let raw_columns = db_ui#completion#get_completions(a:db_key_name, 'columns', table_name)

  " Format for vim-dadbod-completion
  let items = []
  for col in raw_columns
    let item = {
          \ 'word': col.name,
          \ 'abbr': col.name,
          \ 'menu': s:mark,
          \ 'kind': 'C',
          \ 'info': s:format_column_info(col)
          \ }

    " Add data type to menu if available
    if has_key(col, 'data_type') && !empty(col.data_type)
      let item.menu = printf('%s [%s]', s:mark, col.data_type)
    endif

    call add(items, item)
  endfor

  " Filter by base
  if !empty(a:base)
    call filter(items, 'v:val.word =~? "^" . a:base')
  endif

  return items
endfunction

" Get columns from external database
" @param db_key_name - Current database key
" @param external_db - External database name
" @param table_name - Table name
" @param base - Filter text
" @return List of completion items
function! s:get_external_column_completions(db_key_name, external_db, table_name, base) abort
  " Ensure external database metadata is fetched
  call db_ui#completion#fetch_external_database(a:db_key_name, a:external_db)

  " Note: External database column fetching would require additional implementation
  " For now, return empty. This would need table-specific column fetching from external DBs
  " which could be added in a future enhancement.
  return []
endfunction

" Get table completions
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_table_completions(db_key_name, context, base) abort
  let items = []

  " Check if this is for an external database
  if !empty(a:context.database)
    let raw_tables = db_ui#completion#get_external_completions(
          \ a:db_key_name,
          \ a:context.database,
          \ 'all_objects',
          \ a:base
          \ )
  else
    " Get tables and views
    let raw_tables = db_ui#completion#get_completions(a:db_key_name, 'tables')
    let raw_views = db_ui#completion#get_completions(a:db_key_name, 'views')
    call extend(raw_tables, raw_views)
  endif

  " Format items
  for tbl in raw_tables
    let item = {
          \ 'word': tbl.name,
          \ 'abbr': tbl.name,
          \ 'menu': s:mark,
          \ 'kind': tbl.type ==# 'view' ? 'V' : 'T',
          \ 'info': s:format_table_info(tbl)
          \ }

    call add(items, item)
  endfor

  " Filter by base
  if !empty(a:base)
    call filter(items, 'v:val.word =~? "^" . a:base')
  endif

  return items
endfunction

" Get schema completions
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_schema_completions(db_key_name, context, base) abort
  let raw_schemas = db_ui#completion#get_completions(a:db_key_name, 'schemas')

  let items = []
  for schema in raw_schemas
    let schema_name = type(schema) == v:t_string ? schema : schema.name
    let item = {
          \ 'word': schema_name,
          \ 'abbr': schema_name,
          \ 'menu': s:mark,
          \ 'kind': 'S',
          \ 'info': 'Schema'
          \ }
    call add(items, item)
  endfor

  " Filter by base
  if !empty(a:base)
    call filter(items, 'v:val.word =~? "^" . a:base')
  endif

  return items
endfunction

" Get database completions
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_database_completions(db_key_name, context, base) abort
  let raw_databases = db_ui#completion#get_completions(a:db_key_name, 'databases')

  let items = []
  for db in raw_databases
    let db_name = type(db) == v:t_string ? db : db.name
    let item = {
          \ 'word': db_name,
          \ 'abbr': db_name,
          \ 'menu': s:mark,
          \ 'kind': 'D',
          \ 'info': 'Database'
          \ }
    call add(items, item)
  endfor

  " Filter by base
  if !empty(a:base)
    call filter(items, 'v:val.word =~? "^" . a:base')
  endif

  return items
endfunction

" Get procedure completions
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_procedure_completions(db_key_name, context, base) abort
  let raw_procedures = db_ui#completion#get_completions(a:db_key_name, 'procedures')

  let items = []
  for proc in raw_procedures
    let proc_name = type(proc) == v:t_string ? proc : proc.name
    let item = {
          \ 'word': proc_name,
          \ 'abbr': proc_name,
          \ 'menu': s:mark,
          \ 'kind': 'P',
          \ 'info': 'Stored Procedure'
          \ }
    call add(items, item)
  endfor

  " Filter by base
  if !empty(a:base)
    call filter(items, 'v:val.word =~? "^" . a:base')
  endif

  return items
endfunction

" Get function completions
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_function_completions(db_key_name, context, base) abort
  let raw_functions = db_ui#completion#get_completions(a:db_key_name, 'functions')

  let items = []
  for func in raw_functions
    let func_name = type(func) == v:t_string ? func : func.name
    let item = {
          \ 'word': func_name,
          \ 'abbr': func_name,
          \ 'menu': s:mark,
          \ 'kind': 'F',
          \ 'info': 'Function'
          \ }
    call add(items, item)
  endfor

  " Filter by base
  if !empty(a:base)
    call filter(items, 'v:val.word =~? "^" . a:base')
  endif

  return items
endfunction

" Get parameter completions for procedures
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_parameter_completions(db_key_name, context, base) abort
  " Check if we have a procedure name in context
  if empty(a:context.table)
    return []
  endif

  " Note: Parameter fetching would require additional implementation in Phase 2
  " For now, fall back to bind parameters if available
  if exists('b:dbui_bind_params')
    let items = []
    for [param_name, param_val] in items(b:dbui_bind_params)
      call add(items, {
            \ 'word': param_name[1:],
            \ 'abbr': param_name,
            \ 'menu': s:mark,
            \ 'info': param_val,
            \ 'kind': 'P'
            \ })
    endfor

    if !empty(a:base)
      call filter(items, 'v:val.word =~? "^" . a:base')
    endif

    return items
  endif

  return []
endfunction

" Get all object completions (tables, views, procedures, functions)
" @param db_key_name - Database identifier
" @param context - Cursor context
" @param base - Filter text
" @return List of completion items
function! s:get_all_object_completions(db_key_name, context, base) abort
  let items = []

  call extend(items, s:get_table_completions(a:db_key_name, a:context, a:base))
  call extend(items, s:get_procedure_completions(a:db_key_name, a:context, a:base))
  call extend(items, s:get_function_completions(a:db_key_name, a:context, a:base))

  return items
endfunction

" ==============================================================================
" Formatting Helpers
" ==============================================================================

" Format column information for display
" @param column - Column data
" @return Formatted info string
function! s:format_column_info(column) abort
  let info = []

  " Add data type
  if has_key(a:column, 'data_type') && !empty(a:column.data_type)
    call add(info, 'Type: ' . a:column.data_type)
  endif

  " Add nullable
  if has_key(a:column, 'nullable')
    call add(info, a:column.nullable ? 'NULL' : 'NOT NULL')
  endif

  " Add primary key indicator
  if has_key(a:column, 'is_pk') && a:column.is_pk
    call add(info, 'PRIMARY KEY')
  endif

  " Add foreign key indicator
  if has_key(a:column, 'is_fk') && a:column.is_fk
    call add(info, 'FOREIGN KEY')
  endif

  return join(info, ' | ')
endfunction

" Format table information for display
" @param table - Table data
" @return Formatted info string
function! s:format_table_info(table) abort
  let info = []

  " Add type
  call add(info, has_key(a:table, 'type') ? toupper(a:table.type) : 'TABLE')

  " Add schema if available
  if has_key(a:table, 'schema') && !empty(a:table.schema)
    call add(info, 'Schema: ' . a:table.schema)
  endif

  " Add database if external
  if has_key(a:table, 'database') && !empty(a:table.database)
    call add(info, 'Database: ' . a:table.database)
  endif

  return join(info, ' | ')
endfunction
