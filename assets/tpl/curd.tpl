const Table{{.StructTableName}} = "{{.TableName}}"

{{.TableComment}}
type {{.StructTableName}} struct {
{{range $j, $item := .Fields}}	{{$item.Name}}	   {{$item.Type}}	{{$item.FormatFields}}		{{$item.Remark}}
{{end}}}

{{.TableComment}} Null Entity
type {{.NullStructTableName}} struct {
{{range $j, $row := .Fields}}	{{$row.Name}}	{{$row.NullType}}		 {{$row.Remark}}
{{end}}}

func (row *{{.NullStructTableName}}) To{{.StructTableName}}() *{{.StructTableName}} {
	return &{{.StructTableName}}{
	{{- range $j, $row := .Fields}}
	{{- if eq $row.Type "float64"}}
		{{$row.Name}}:	row.{{$row.Name}}.Float64,	{{$row.Remark}}
	{{- else if eq $row.Type "float"}}
		{{$row.Name}}:	row.{{$row.Name}}.Float,	{{$row.Remark}}
	{{- else if eq $row.Type "int64"}}
		{{$row.Name}}:	row.{{$row.Name}}.Int64,	{{$row.Remark}}
	{{- else if eq $row.Type "int"}}
		{{$row.Name}}:	row.{{$row.Name}}.Int,	{{$row.Remark}}
	{{- else if eq $row.Type "time.Time"}}
		{{$row.Name}}:	row.{{$row.Name}}.Time,	{{$row.Remark}}
	{{- else}}
		{{$row.Name}}:	row.{{$row.Name}}.String,	{{$row.Remark}}
	{{- end}}
	{{- end}}
	}
}

type {{.StructTableName}}Model struct {
	DB *gorm.DB
}

func New{{.StructTableName}}(db ...*gorm.DB) (*{{.StructTableName}}Model, error) {
	if len(db) > 0 {
		return &{{.StructTableName}}Model{
			DB: db[0],
		}, nil
	}
	if conn, err := conf.DefaultConf.GetDb(false); err!=nil {
		return nil, err
	}else{
		return &{{.StructTableName}}Model{
			DB: conn,
		}, nil
	}
}

// 获取所有的表字段
func (m *{{.StructTableName}}Model) getColumns() string {
	return " {{.AllFieldList}} "
}

// 获取多行数据.
func (m *{{.StructTableName}}Model) getRows(sqlTxt string, params ...interface{}) (rowsResult []*{{.StructTableName}}, err error) {
	query, err := m.DB.DB().Query(sqlTxt, params...)
	if err != nil {
		return
	}
	defer func() {
		if err:=query.Close(); err!=nil {
			fmt.Printf("释放数据库连接失败。%v\r\n", err)
		}
	}()
	for query.Next() {
		row := {{.NullStructTableName}}{}
		err = query.Scan(
		{{range .NullFieldsInfo}}&row.{{.HumpName}},// {{.Comment}}
		{{end}})
		if nil != err {
			fmt.Printf("查询失败。%v\r\n", err)
			continue
		}
		rowsResult = append(rowsResult, row.To{{.StructTableName}}())
	}
	return
}

// 获取单行数据
func (m *{{.StructTableName}}Model) getRow(sqlText string, params ...interface{}) (rowResult *{{.StructTableName}}, err error) {
	query := m.DB.DB().QueryRow(sqlText, params...)
	row := {{.NullStructTableName}}{}
	err = query.Scan(
	{{range .NullFieldsInfo}}&row.{{.HumpName}},// {{.Comment}}
	{{end}})
	if err != sql.ErrNoRows {
		fmt.Printf("查询失败。%v\r\n", err)
		return
	}
	rowResult = row.To{{.StructTableName}}()
	return
}

// _更新数据
func (m *{{.StructTableName}}Model) Save(sqlTxt string, value ...interface{}) (b bool, err error) {
	stmt, err := m.DB.DB().Prepare(sqlTxt)
	defer func() {
		if err:=stmt.Close(); err!=nil {
			fmt.Printf("释放数据库连接失败。%v\r\n", err)
		}
	}()
	result, err := stmt.Exec(value...)
	if err != nil {
		return
	}
	var affectCount int64
	affectCount, err = result.RowsAffected()
	if err != nil {
		return
	}
	b = affectCount > 0
	return
}

// 新增信息
func (m *{{.StructTableName}}Model) Create(value *{{.StructTableName}}) error {
	const sqlText = "INSERT INTO " + Table{{.StructTableName}} + " ({{.InsertFieldList}}) VALUES ({{.InsertMark}})"
	stmt, err := m.DB.DB().Prepare(sqlText)
	if err != nil {
		return err
	}
	defer func() {
		if err:=stmt.Close(); err!=nil {
			fmt.Printf("释放数据库连接失败。%v\r\n", err)
		}
	}()
	_, err = stmt.Exec(
	{{range .InsertInfo}}value.{{.HumpName}},// {{.Comment}}
	{{end}})
	if err != nil {
		return err
	}
	return nil
}

// 更新数据
func (m *{{.StructTableName}}Model) Update(value *{{.StructTableName}}) (b bool, err error) {
	sqlText := "UPDATE " + Table{{.StructTableName}} + " SET {{.UpdateFieldList}} WHERE {{.PrimaryKey}} = ?"
	params := make([]interface{}, 0)
	{{range $i, $val := .UpdateListField}}params = append(params, {{$val}})
	{{end}}
	return m.Save(sqlText, params...)
}

// 查询多行数据
func (m *{{.StructTableName}}Model) All() (resList []*{{.StructTableName}}, err error) {
	sqlText := "SELECT" + m.getColumns() + "FROM " + Table{{.StructTableName}}
	resList, err = m.getRows(sqlText)
	return
}

// 获取单行数据
func (m *{{.StructTableName}}Model) First() (result *{{.StructTableName}}, err error) {
	sqlText := "SELECT" + m.getColumns() + "FROM " + Table{{.StructTableName}} + " LIMIT 1"
	result, err = m.getRow(sqlText)
	if err != nil {
		return
	}
	return
}

// 获取最后一行数据
func (m *{{.StructTableName}}Model) Last() (result *{{.StructTableName}}, err error) {
	sqlText := "SELECT" + m.getColumns() + "FROM " + Table{{.StructTableName}} + " ORDER BY ID DESC LIMIT 1"
	result, err = m.getRow(sqlText)
	if err != nil {
		return
	}
	return
}

// 获取行数
func (m *{{.StructTableName}}Model) Count() (count int64, err error) {
	sqlText := "SELECT COUNT(*) FROM " + Table{{.StructTableName}}
	query := m.DB.DB().QueryRow(sqlText)
	err = query.Scan(&count)
	if err != nil {
		return
	}
	return
}

// 判断是否存在
func (m *{{.StructTableName}}Model) Exists(id int64) (b bool, err error) {
	sqlText := "SELECT COUNT(*) FROM " + Table{{.StructTableName}} + " where id = ?"
	query := m.DB.DB().QueryRow(sqlText, id)
	var count int64
	err = query.Scan(&count)
	if err != nil {
		return
	}
	if count > 0 {
		b = true
		return
	}
	return
}

// 按指定的条件查询列表
func (m *{{.StructTableName}}Model) Find(where *{{.StructTableName}}) (resList []*{{.StructTableName}}, err error) {
	m.DB.Error=nil
	m.DB.Where(where).Find(&resList).Order("{{.PrimaryKey}} desc")
	err = m.DB.Error
	return
}