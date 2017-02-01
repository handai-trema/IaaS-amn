var pre_data;
var nodes;
var edges;
var network;

$(function(){
    var add_table_name_empty;
    var add_table;

    add_table_name_empty = function(con_num){
	var table_html = create_table_html_name_empty(con_num);
	$('#con_name_table_field').html(table_html);
    };

    add_table = function(con_num,base_name){
	var table_html = create_table_html(con_num,base_name);
	$('#con_name_table_field').html(table_html);
    };

    add_con_name_ip = function(con_name_ip){
	var con_ip_html = create_con_ip_table_html(con_name_ip);
	console.log($('#con_name_ip_table'));
	$('#con_name_ip_table').html(con_ip_html);
    };

    $('#con_name_input').on('click', function(){
	var con_num = parseInt($('#con_num').val());
	add_table_name_empty(con_num);
    });

    $('#con_base_name_input').on('click', function(){
	var con_num = parseInt($('#con_num').val());
	var base_name = $('#con_base_name').val();
	add_table(con_num,base_name);
    });

    $('#con_name_table_field').on('click','#create_input', function(){
	console.log("create_input_click");
	var con_num = parseInt($('#con_num').val());
	for(var i = 0;i < con_num;i++){
	    var input_id = "#con_name_" + i;
	    var con_name = $(input_id).val();
	    create_container_rest_api(con_name);
	}
	add_con_name_ip(show_container_rest_api());
    });
});

function create_con_ip_table_html(con_ip_table){
    return "<span>" + con_ip_table + " </span>";
}

function create_table_html_name_empty(con_num){
    var re = "<h2> コンテナの名前テーブル </h2>";
    re += '<table border="1" id="con_name_table">';
    re += '<thead><tr><th>名前</th></tr></thead>';
    re += '<tbody>';
    for(var i = 0;i < con_num;i++){
	re += '<tr><td><input id="con_name_' + i + '" type="text"></td></tr>';
    }
    re += '</tbody></table>';
    re += '<button id="create_input" type="button"> コンテナの作成 </button>';
    return re;
}

function create_table_html(con_num,base_name){
    var re = "<h2> コンテナの名前テーブル </h2>";
    re += '<table border="1" id="con_name_table">';
    re += '<thead><tr><th>名前</th></tr></thead>';
    re += '<tbody>';
    for(var i = 0;i < con_num;i++){
	var name = base_name + i;
	re += '<tr><td><input id="con_name_' + i + '" type="text" value="' + name + '"></td></tr>';
    }
    re += '</tbody></table>';
    re += '<button id="create_input" type="button"> コンテナの作成 </button>';
    return re;
}

function create_container_rest_api(con_name){
    var url = './php/index.php?con_name=' + con_name;
    var xhr = $.ajax({
	type: 'GET',
	url: url,
	dataType: 'text',
	async: false,
	timeout: 30000
    });
    xhr.success(function(data){
	console.log("create_container");
	console.log(data);
    });
    xhr.error(function(data){
	console.log("create_container error");
	console.log(data);
    });
    xhr.complete(function(data){
    });
}

function show_container_rest_api(){
    var url = './php/index.php?show=sh';
    var re;
    var xhr = $.ajax({
	type: 'GET',
	url: url,
	dataType: 'text',
	async: false,
	timeout: 30000
    });
    xhr.success(function(data){
	console.log("show_container");
	console.log(data);
    });
    xhr.error(function(data){
	console.log("show_container error");
	console.log(data);
    });
    xhr.complete(function(data){
    });
    return re;
}
